/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation
import os.log

/// Level and category a method's success record is logged under; errors ignore it.
public struct MethodLogMetadata {
    public let level: LogLevel?
    public let category: LogCategory?

    public init(level: LogLevel? = nil, category: LogCategory? = nil) {
        self.level = level
        self.category = category
    }
}

/// Local diagnostic logger for the Scandit Data Capture SDK (iOS side).
///
/// Privacy guarantee: this logger is entirely local to the device. It writes
/// to `os_log` (Console.app), to the in-memory ring buffer and, while the level
/// is above Off and a directory was set with `setLogDirectory`, to a rolling
/// log file in the app's private storage. When an `Emitter` is registered via
/// `registerEmitter`, records are also batched and shipped to the framework's
/// JS/Dart layer over the same event channel the SDK already uses — they never
/// leave the device by any other route. The SDK does not collect or transmit
/// log data; the frameworks' `writeLogs` command copies it to a path the
/// caller names.
///
/// The logger is off by default. Call `setLevel(.debug)` to enable.
public final class ScanditLogger {
    public static let shared = ScanditLogger()

    private static let batchEvent = "ScanditLogger.batch"
    private static let bufferCapacity = 1000
    static let batchMaxRecords = 50
    private static let batchFlushIntervalMs: Double = 100

    private let osLog = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "com.scandit.datacapture",
        category: "ScanditLogger"
    )
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let stateLock = NSLock()
    private var level: LogLevel = .off
    private var buffer: [LogRecord?] = Array(repeating: nil, count: bufferCapacity)
    private var writeIdx: Int = 0
    private var count: Int64 = 0
    /// Subscribers are keyed by a monotonic token rather than stored as a bare
    /// array, so an unsubscribe closure removes exactly the callback it was
    /// handed out for. An index captured at subscribe time would go stale as
    /// soon as any earlier subscriber unsubscribed and the array shifted.
    /// An array (not a dictionary) keeps notification order stable.
    private var subscribers: [(token: UInt64, callback: (LogRecord) -> Void)] = []
    private var nextSubscriberToken: UInt64 = 0
    private var methodMetadata: [String: MethodLogMetadata] = [:]

    private let emitterLock = NSLock()
    private var emitter: Emitter?
    private var pendingBatch: [LogRecord] = []
    private var flushScheduled = false
    private let flushQueue = DispatchQueue(label: "com.scandit.logger.flush", qos: .utility)

    /// Work that takes or drops `pendingFileRecords` is enqueued while holding this lock, so
    /// `flushQueue` runs it in the order the records were taken.
    private let fileLock = NSLock()
    private var rollingFile: RollingLogFile?
    private var exportFile: URL?
    private var pendingFileRecords: [LogRecord] = []
    private var fileFlushScheduled = false

    private init() {}

    // MARK: - Configuration

    public func setLevel(_ newLevel: LogLevel) {
        stateLock.lock()
        defer { stateLock.unlock() }
        level = newLevel
    }

    public func getLevel() -> LogLevel {
        stateLock.lock()
        defer { stateLock.unlock() }
        return level
    }

    // MARK: - Buffer

    public func getRecentLogs() -> [LogRecord] {
        stateLock.lock()
        defer { stateLock.unlock() }
        let total = Int(min(count, Int64(Self.bufferCapacity)))
        let start = count < Int64(Self.bufferCapacity) ? 0 : writeIdx
        var out: [LogRecord] = []
        out.reserveCapacity(total)
        for i in 0..<total {
            if let record = buffer[(start + i) % Self.bufferCapacity] {
                out.append(record)
            }
        }
        return out
    }

    @discardableResult
    public func subscribe(_ callback: @escaping (LogRecord) -> Void) -> () -> Void {
        stateLock.lock()
        let token = nextSubscriberToken
        nextSubscriberToken &+= 1
        subscribers.append((token: token, callback: callback))
        stateLock.unlock()
        return { [weak self] in
            guard let self = self else { return }
            self.stateLock.lock()
            defer { self.stateLock.unlock() }
            self.subscribers.removeAll { $0.token == token }
        }
    }

    public func clear() {
        stateLock.lock()
        defer { stateLock.unlock() }
        buffer = Array(repeating: nil, count: Self.bufferCapacity)
        writeIdx = 0
        count = 0
    }

    // MARK: - Method metadata

    /// Merges per-method level/category overrides, keyed by bridge method name. Called by each
    /// target's generated `LogMetadata`; last write wins for duplicate keys.
    public func registerMethodMetadata(_ metadata: [String: MethodLogMetadata]) {
        stateLock.lock()
        defer { stateLock.unlock() }
        methodMetadata.merge(metadata) { _, new in new }
    }

    public func getMethodMetadata(_ methodName: String) -> MethodLogMetadata? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return methodMetadata[methodName]
    }

    /// Test-only.
    public func clearMethodMetadata() {
        stateLock.lock()
        defer { stateLock.unlock() }
        methodMetadata.removeAll()
    }

    /// Register the iOS-side `Emitter` so log records are also shipped to the
    /// JS/Dart layer in batches. Call once during module construction. Pass
    /// `nil` to detach (useful in tests).
    public func registerEmitter(_ newEmitter: Emitter?) {
        emitterLock.lock()
        defer { emitterLock.unlock() }
        emitter = newEmitter
        if newEmitter == nil {
            pendingBatch.removeAll()
            flushScheduled = false
        }
    }

    // MARK: - Log file

    /// Where records are kept across restarts; `nil` stops writing. Pointing at the same directory again keeps it.
    public func setLogDirectory(_ directory: URL?) {
        fileLock.lock()
        defer { fileLock.unlock() }
        if directory == rollingFile?.directory { return }
        pendingFileRecords.removeAll()
        rollingFile = directory.map { RollingLogFile(directory: $0) }
    }

    /// Appends JSON lines produced by the TypeScript/Dart side to the rolling file, verbatim.
    public func appendLines(_ lines: String) {
        fileLock.lock()
        let file = rollingFile
        fileLock.unlock()
        guard let file = file else { return }
        flushQueue.async { file.append(lines) }
    }

    /// Writes what is pending and waits until every earlier file write has finished. Blocks the
    /// caller, so bridge handlers use `readLogFiles(_:)` and `deleteLogFiles(_:)` instead.
    public func flushLogFile() {
        let written = DispatchGroup()
        fileLock.lock()
        if let file = rollingFile {
            let batch = takePendingFileRecords()
            flushQueue.async(group: written) { self.writeToFile(file, batch) }
        }
        fileLock.unlock()
        written.wait()
    }

    /// The default writeLogs() destination, deleted together with the rolling files.
    public func setExportFile(_ file: URL?) {
        fileLock.lock()
        defer { fileLock.unlock() }
        exportFile = file
    }

    /// Returns at once. On the file queue, after every earlier write, passes everything stored in
    /// the rolling files, oldest first, to `completion` on that queue; "" when no directory is set.
    public func readLogFiles(_ completion: @escaping (String) -> Void) {
        fileLock.lock()
        let file = rollingFile
        let batch = takePendingFileRecords()
        flushQueue.async {
            guard let file = file else {
                completion("")
                return
            }
            self.writeToFile(file, batch)
            completion(file.readAll())
        }
        fileLock.unlock()
    }

    /// Returns at once. Drops the pending records, then, on the file queue after every earlier
    /// write, deletes both rolling files and the default export and calls `completion` there.
    public func deleteLogFiles(_ completion: @escaping () -> Void) {
        fileLock.lock()
        let file = rollingFile
        let export = exportFile
        pendingFileRecords.removeAll()
        flushQueue.async {
            if let export = export { try? FileManager.default.removeItem(at: export) }
            file?.delete()
            completion()
        }
        fileLock.unlock()
    }

    // MARK: - Emit

    public func emit(
        level recordLevel: LogLevel,
        category: LogCategory,
        source: String,
        message: String,
        fields: [String: Any?]? = nil,
        durationMs: Int64? = nil,
        error: LogRecordError? = nil
    ) {
        if recordLevel == .off { return }
        let (configuredLevel, override) = stateLock.withLock {
            (level, recordLevel == .error ? nil : methodMetadata[message])
        }
        if configuredLevel == .off { return }
        let effectiveLevel = override?.level ?? recordLevel
        let effectiveCategory = override?.category ?? category
        if effectiveLevel.rawValue > configuredLevel.rawValue { return }

        let record = LogRecord(
            ts: Int64(Date().timeIntervalSince1970 * 1000),
            level: effectiveLevel,
            category: effectiveCategory,
            source: source,
            message: message,
            fields: LogRedaction.redactFields(message: message, fields: fields),
            durationMs: durationMs,
            error: error.map { LogRecordError(name: $0.name, message: $0.message) }
        )

        stateLock.lock()
        buffer[writeIdx] = record
        writeIdx = (writeIdx + 1) % Self.bufferCapacity
        count &+= 1
        let subs = subscribers
        stateLock.unlock()

        writeToOSLog(record)
        for sub in subs {
            sub.callback(record)
        }
        queueForBatch(record)
        queueForFile(record)
    }

    public func format(_ record: LogRecord) -> String {
        formatLine(record, includeArgs: true)
    }

    /// - Parameter includeArgs: when `false`, `fields["args"]` is omitted.
    ///   Required for anything written to the platform logger — see
    ///   `platformLogLine`.
    private func formatLine(_ record: LogRecord, includeArgs: Bool) -> String {
        let ts = isoFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(record.ts) / 1000))
        var parts: [String] = [ts, record.level.tag, "[\(record.category.name)]"]
        parts.append(record.source.padding(toLength: 16, withPad: " ", startingAt: 0))
        parts.append(record.message)
        if let d = record.durationMs { parts.append("duration=\(d)ms") }
        if var f = record.fields, !f.isEmpty {
            if !includeArgs { f.removeValue(forKey: "args") }
            if !f.isEmpty { parts.append("fields=\(f)") }
        }
        if let e = record.error { parts.append("error=\(e.name): \(e.message)") }
        return sanitize(parts.joined(separator: "  "))
    }

    // MARK: - Internals

    /// The exact line handed to the platform logger.
    ///
    /// os_log output is readable off the device and emitted as `%{public}@`, so bridge args stay
    /// out of it even though `emit` already redacted them.
    ///
    /// Kept as a named function rather than a `Bool` at the `os_log` call site:
    /// `os_log` output cannot be observed from a unit test, so stating the
    /// guarantee in one covered place is what keeps it from regressing.
    func platformLogLine(_ record: LogRecord) -> String {
        formatLine(record, includeArgs: false)
    }

    private func writeToOSLog(_ record: LogRecord) {
        let line = platformLogLine(record)
        let type: OSLogType
        switch record.level {
        case .error: type = .error
        case .warn: type = .default
        case .info: type = .info
        case .debug, .trace: type = .debug
        case .off: return
        }
        os_log("%{public}@", log: osLog, type: type, line)
    }

    private func queueForBatch(_ record: LogRecord) {
        emitterLock.lock()
        guard emitter != nil else {
            emitterLock.unlock()
            return
        }
        pendingBatch.append(record)
        if pendingBatch.count >= Self.batchMaxRecords {
            let batch = pendingBatch
            pendingBatch.removeAll()
            let em = emitter
            emitterLock.unlock()
            shipBatch(em, batch)
            return
        }
        if !flushScheduled {
            flushScheduled = true
            emitterLock.unlock()
            flushQueue.asyncAfter(deadline: .now() + .milliseconds(Int(Self.batchFlushIntervalMs))) { [weak self] in
                self?.flushPending()
            }
            return
        }
        emitterLock.unlock()
    }

    private func queueForFile(_ record: LogRecord) {
        fileLock.lock()
        guard let file = rollingFile else {
            fileLock.unlock()
            return
        }
        pendingFileRecords.append(record)
        if pendingFileRecords.count >= Self.batchMaxRecords {
            let batch = takePendingFileRecords()
            flushQueue.async { self.writeToFile(file, batch) }
            fileLock.unlock()
            return
        }
        let schedule = !fileFlushScheduled
        fileFlushScheduled = true
        fileLock.unlock()
        if schedule {
            flushQueue.asyncAfter(deadline: .now() + .milliseconds(Int(Self.batchFlushIntervalMs))) { [weak self] in
                self?.flushPendingFileRecords()
            }
        }
    }

    private func flushPendingFileRecords() {
        fileLock.lock()
        fileFlushScheduled = false
        let file = rollingFile
        let batch = takePendingFileRecords()
        fileLock.unlock()
        if let file = file { writeToFile(file, batch) }
    }

    /// Callers hold `fileLock`.
    private func takePendingFileRecords() -> [LogRecord] {
        let batch = pendingFileRecords
        pendingFileRecords.removeAll()
        return batch
    }

    private func writeToFile(_ file: RollingLogFile, _ records: [LogRecord]) {
        guard !records.isEmpty else { return }
        file.append(records.map { logLine(for: $0) }.joined(separator: "\n"))
    }

    /// One JSON line in the shape the frameworks' `writeLogs` export body uses for a record.
    private func logLine(for record: LogRecord) -> String {
        var line: [String: Any] = [
            "ts": record.ts,
            "level": record.level.tag.trimmingCharacters(in: .whitespaces),
            "category": record.category.name,
            "source": record.source,
            "message": record.message,
            "time": isoFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(record.ts) / 1000)),
        ]
        if let fields = record.fields { line["fields"] = Self.jsonSafe(fields) }
        if let duration = record.durationMs { line["durationMs"] = duration }
        if let error = record.error { line["error"] = ["name": error.name, "message": error.message] }
        let data = try? JSONSerialization.data(withJSONObject: line, options: [.sortedKeys, .withoutEscapingSlashes])
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }

    private static func jsonSafe(_ value: Any?) -> Any {
        switch value {
        case nil, is NSNull: return NSNull()
        case let string as String: return string
        // JSONSerialization raises an uncatchable exception on NaN and infinity.
        case let number as NSNumber: return number.doubleValue.isFinite ? number : number.stringValue
        case let dict as [String: Any?]: return dict.mapValues { jsonSafe($0) }
        case let array as [Any?]: return array.map { jsonSafe($0) }
        default: return "\(value as Any)"
        }
    }

    private func flushPending() {
        emitterLock.lock()
        flushScheduled = false
        guard let em = emitter, !pendingBatch.isEmpty else {
            emitterLock.unlock()
            return
        }
        let batch = pendingBatch
        pendingBatch.removeAll()
        emitterLock.unlock()
        shipBatch(em, batch)
    }

    private func shipBatch(_ em: Emitter?, _ records: [LogRecord]) {
        guard let em = em else { return }
        let payload: [String: Any?] = ["records": records.map { $0.toBridgePayload() }]
        em.emit(name: Self.batchEvent, payload: payload)
    }

    /// Sanitizes log messages to prevent log forging (CWE-117).
    private func sanitize(_ message: String) -> String {
        var out = ""
        out.reserveCapacity(message.count)
        for scalar in message.unicodeScalars {
            let value = scalar.value
            if value == 0x0A || value == 0x0D {
                out.append(" ")
            } else if (value <= 0x1F) || value == 0x7F {
                continue
            } else {
                out.unicodeScalars.append(scalar)
            }
        }
        return out
    }
}

private extension NSLock {
    func withLock<R>(_ body: () -> R) -> R {
        lock()
        defer { unlock() }
        return body()
    }
}
