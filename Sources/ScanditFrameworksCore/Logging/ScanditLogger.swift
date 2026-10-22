/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation
import os.log

/// Local, in-memory diagnostic logger for the Scandit Data Capture SDK (iOS side).
///
/// Privacy guarantee: this logger is entirely local to the app process. It
/// writes only to `os_log` (Console.app) and to the in-memory ring buffer.
/// When an `Emitter` is registered via `registerEmitter`, records are also
/// batched and shipped to the framework's JS/Dart layer over the same event
/// channel the SDK already uses — they never leave the device by any other
/// route. The SDK does not collect or transmit log data, and persists it only
/// where the app asks it to: the frameworks' `writeLogs` command serializes the
/// buffer to a path the caller names.
///
/// The logger is off by default. Call `setLevel(.debug)` to enable.
public final class ScanditLogger {
    public static let shared = ScanditLogger()

    private static let batchEvent = "ScanditLogger.batch"
    private static let defaultBufferSize = 1000
    private static let minBufferSize = 1
    private static let batchMaxRecords = 50
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
    private var categories: LogCategory = LogCategory.defaults
    private var bufferSize: Int = defaultBufferSize
    private var buffer: [LogRecord?] = Array(repeating: nil, count: defaultBufferSize)
    private var writeIdx: Int = 0
    private var count: Int64 = 0
    /// Subscribers are keyed by a monotonic token rather than stored as a bare
    /// array, so an unsubscribe closure removes exactly the callback it was
    /// handed out for. An index captured at subscribe time would go stale as
    /// soon as any earlier subscriber unsubscribed and the array shifted.
    /// An array (not a dictionary) keeps notification order stable.
    private var subscribers: [(token: UInt64, callback: (LogRecord) -> Void)] = []
    private var nextSubscriberToken: UInt64 = 0

    private let emitterLock = NSLock()
    private var emitter: Emitter?
    private var pendingBatch: [LogRecord] = []
    private var flushScheduled = false
    private let flushQueue = DispatchQueue(label: "com.scandit.logger.flush", qos: .utility)

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

    public func setCategories(_ mask: LogCategory) {
        stateLock.lock()
        defer { stateLock.unlock() }
        categories = mask
    }

    public func getCategories() -> LogCategory {
        stateLock.lock()
        defer { stateLock.unlock() }
        return categories
    }

    public func setBufferSize(_ size: Int) {
        stateLock.lock()
        defer { stateLock.unlock() }
        let next = max(Self.minBufferSize, size)
        if next == bufferSize { return }
        bufferSize = next
        buffer = Array(repeating: nil, count: next)
        writeIdx = 0
        count = 0
    }

    public func getBufferSize() -> Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        return bufferSize
    }

    // MARK: - Buffer

    public func getRecentLogs() -> [LogRecord] {
        stateLock.lock()
        defer { stateLock.unlock() }
        let size = bufferSize
        let total = Int(min(count, Int64(size)))
        let start = count < Int64(size) ? 0 : writeIdx
        var out: [LogRecord] = []
        out.reserveCapacity(total)
        for i in 0..<total {
            if let record = buffer[(start + i) % size] {
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
        buffer = Array(repeating: nil, count: bufferSize)
        writeIdx = 0
        count = 0
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
        let (configuredLevel, configuredCategories) = stateLock.withLock { (level, categories) }
        if configuredLevel == .off { return }
        if recordLevel.rawValue > configuredLevel.rawValue { return }
        if !configuredCategories.contains(category) { return }

        let record = LogRecord(
            ts: Int64(Date().timeIntervalSince1970 * 1000),
            level: recordLevel,
            category: category,
            source: source,
            message: message,
            fields: fields,
            durationMs: durationMs,
            error: error
        )

        stateLock.lock()
        buffer[writeIdx] = record
        writeIdx = (writeIdx + 1) % bufferSize
        count &+= 1
        let subs = subscribers
        stateLock.unlock()

        writeToOSLog(record)
        for sub in subs {
            sub.callback(record)
        }
        queueForBatch(record)
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
    /// `fields["args"]` carries raw bridge arguments straight from
    /// `LoggingCommand.extractFields()`, and os_log output is readable off the
    /// device (Console.app, sysdiagnose) — the line is emitted as `%{public}@`.
    /// Redaction of sensitive keys (licenseKey and any set via
    /// `setAdditionalRedactedArgKeys`) lives on the TS side, where `ScanditLogger.ingest`
    /// applies it before native records enter the unified buffer; the native
    /// side is never told the customer-configured key set, so it cannot redact
    /// faithfully. Raw args therefore must not reach the platform logger — they
    /// remain available locally via `getRecentLogs()` and `format`.
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
