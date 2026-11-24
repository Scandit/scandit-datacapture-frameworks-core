/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class ScanditLoggerTests: XCTestCase {
    private var unsubscribers: [() -> Void] = []

    override func setUp() {
        super.setUp()
        ScanditLoggerTestSupport.resetLogger()
    }

    override func tearDown() {
        unsubscribers.forEach { $0() }
        unsubscribers.removeAll()
        ScanditLoggerTestSupport.resetLogger()
        super.tearDown()
    }

    private func track(_ unsubscribe: @escaping () -> Void) {
        unsubscribers.append(unsubscribe)
    }

    // MARK: - level gating

    func testDefaultLevelOffDropsEveryRecord() {
        // level is .off by default (see resetLogger)
        ScanditLogger.shared.emit(level: .error, category: .bridge, source: "src", message: "msg")
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    func testLevelInfoKeepsErrorWarnAndInfoButDropsDebugAndTrace() {
        ScanditLogger.shared.setLevel(.info)
        ScanditLogger.shared.emit(level: .error, category: .bridge, source: "src", message: "error-msg")
        ScanditLogger.shared.emit(level: .warn, category: .bridge, source: "src", message: "warn-msg")
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "info-msg")
        ScanditLogger.shared.emit(level: .debug, category: .bridge, source: "src", message: "debug-msg")
        ScanditLogger.shared.emit(level: .trace, category: .bridge, source: "src", message: "trace-msg")
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, ["error-msg", "warn-msg", "info-msg"])
    }

    func testEmitAtLevelOffIsAlwaysDroppedEvenWhenConfiguredLevelIsTrace() {
        // Swift-specific: `emit` returns early for recordLevel == .off regardless
        // of configuration, before the level gate even runs.
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.emit(level: .off, category: .bridge, source: "src", message: "msg")
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    // MARK: - level is the only filter

    private let allCategories: [LogCategory] = [.bridge, .lifecycle, .listener, .events]

    func testTraceIsHiddenAtDebugWhateverTheCategory() {
        ScanditLogger.shared.setLevel(.debug)
        for category in allCategories {
            ScanditLogger.shared.emit(level: .trace, category: category, source: "src", message: "msg")
        }
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    func testTraceOfEveryCategoryIsKeptAtTrace() {
        ScanditLogger.shared.setLevel(.trace)
        for category in allCategories {
            ScanditLogger.shared.emit(level: .trace, category: category, source: "src", message: "msg")
        }
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().map { $0.category }, allCategories)
    }

    // MARK: - method metadata override

    func testARegisteredMethodOverrideLogsTheSuccessRecordAtItsLevelAndCategory() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.registerMethodMetadata([
            "finishX": MethodLogMetadata(level: .trace, category: .events)
        ])
        ScanditLogger.shared.emit(level: .debug, category: .bridge, source: "src", message: "finishX")
        let record = ScanditLogger.shared.getRecentLogs().first
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().count, 1)
        XCTAssertEqual(record?.level, .trace)
        XCTAssertEqual(record?.category, .events)
    }

    func testATraceMarkedMethodIsHiddenAtDebug() {
        ScanditLogger.shared.setLevel(.debug)
        ScanditLogger.shared.registerMethodMetadata([
            "finishX": MethodLogMetadata(level: .trace, category: .events)
        ])
        ScanditLogger.shared.emit(level: .debug, category: .bridge, source: "src", message: "finishX")
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    func testTheLastRegistrationWinsWhenTwoTargetsRegisterTheSameMethodName() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.registerMethodMetadata(["finishX": MethodLogMetadata(level: .trace, category: .listener)])
        ScanditLogger.shared.registerMethodMetadata(["finishX": MethodLogMetadata(level: .trace, category: .events)])
        XCTAssertEqual(ScanditLogger.shared.getMethodMetadata("finishX")?.category, .events)
        ScanditLogger.shared.emit(level: .debug, category: .bridge, source: "src", message: "finishX")
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().first?.category, .events)
    }

    func testAnErrorOnAnOverriddenMethodKeepsItsLevelAndCallerCategory() {
        ScanditLogger.shared.setLevel(.error)
        ScanditLogger.shared.registerMethodMetadata([
            "finishX": MethodLogMetadata(level: .trace, category: .events)
        ])
        ScanditLogger.shared.emit(level: .error, category: .bridge, source: "src", message: "finishX")
        let record = ScanditLogger.shared.getRecentLogs().first
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().count, 1)
        XCTAssertEqual(record?.level, .error)
        XCTAssertEqual(record?.category, .bridge)
    }

    // MARK: - LogLevel.fromRank

    func testFromRankRoundTripsEveryValidRank() {
        for level in LogLevel.allCases {
            XCTAssertEqual(LogLevel.fromRank(level.rawValue), level)
        }
    }

    func testFromRankFallsBackToOffForAnOutOfRangeRank() {
        XCTAssertEqual(LogLevel.fromRank(99), .off)
        XCTAssertEqual(LogLevel.fromRank(-1), .off)
    }

    // MARK: - LogLevel.tag

    func testTagReturnsTheFixedWidthLabelForEachLevel() {
        XCTAssertEqual(LogLevel.off.tag, "OFF  ")
        XCTAssertEqual(LogLevel.error.tag, "ERROR")
        XCTAssertEqual(LogLevel.warn.tag, "WARN ")
        XCTAssertEqual(LogLevel.info.tag, "INFO ")
        XCTAssertEqual(LogLevel.debug.tag, "DEBUG")
        XCTAssertEqual(LogLevel.trace.tag, "TRACE")
    }

    // MARK: - LogCategory.name

    func testCategoryNameForEachSingleBit() {
        XCTAssertEqual(LogCategory.bridge.name, "Bridge")
        XCTAssertEqual(LogCategory.lifecycle.name, "Lifecycle")
        XCTAssertEqual(LogCategory.listener.name, "Listener")
        XCTAssertEqual(LogCategory.events.name, "Events")
    }

    func testCategoryNameForACombinedOrUnknownMaskIsUnknown() {
        XCTAssertEqual(LogCategory([.bridge, .events]).name, "Unknown")
        XCTAssertEqual(LogCategory(rawValue: 0).name, "Unknown")
        XCTAssertEqual(LogCategory(rawValue: 1 << 10).name, "Unknown")
    }

    // MARK: - ring buffer

    private func emitNumbered(_ count: Int) {
        (1...count).forEach {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg-\($0)")
        }
    }

    func testBelowCapacityKeepsAllRecordsInOldestFirstInsertionOrder() {
        ScanditLogger.shared.setLevel(.trace)
        emitNumbered(5)
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, (1...5).map { "msg-\($0)" })
    }

    func testExactlyAtTheFixedCapacityKeepsAllRecords() {
        ScanditLogger.shared.setLevel(.trace)
        emitNumbered(1000)
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, (1...1000).map { "msg-\($0)" })
    }

    func testBeyondTheFixedCapacityEvictsTheOldestAndKeepsExactly1000Records() {
        ScanditLogger.shared.setLevel(.trace)
        emitNumbered(1005)
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, (6...1005).map { "msg-\($0)" })
    }

    func testRingBufferPreservesOldestToNewestOrderAfterWrappingMoreThanTwice() {
        ScanditLogger.shared.setLevel(.trace)
        emitNumbered(2500)
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, (1501...2500).map { "msg-\($0)" })
    }

    // MARK: - clear

    func testClearEmptiesTheBuffer() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        ScanditLogger.shared.clear()
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    // MARK: - os_log privacy (platformLogLine seam)

    func testPlatformLogLineOmitsArgsWholesaleWhileGetRecentLogsAndFormatKeepTheRedactedOnes() {
        ScanditLogger.shared.setLevel(.debug)
        let fields: [String: Any?] = [
            "modeId": 7,
            "args": ["licenseKey": "SECRET-KEY-VALUE", "units": "mm"],
        ]
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: "msg",
            fields: fields
        )
        let record = ScanditLogger.shared.getRecentLogs().first!

        let logLine = ScanditLogger.shared.platformLogLine(record)
        XCTAssertFalse(logLine.contains("units"))
        XCTAssertTrue(logLine.contains("modeId"))

        let formatted = ScanditLogger.shared.format(record)
        XCTAssertTrue(formatted.contains("units"))
        XCTAssertFalse(formatted.contains("SECRET-KEY-VALUE"))
    }

    func testALicenseKeyInsideAJSONStringArgValueIsRedactedInTheBuffer() {
        ScanditLogger.shared.setLevel(.debug)
        let settingsJson = #"{"licenseKey":"SECRET-INSIDE-JSON","enabled":true}"#
        let innerArgs: [String: Any?] = ["settingsJson": settingsJson]
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: "msg",
            fields: ["args": innerArgs]
        )

        let bufferedArgs = ScanditLogger.shared.getRecentLogs().first?.fields?["args"] as? [String: Any?]
        let stored =
            try? JSONSerialization.jsonObject(
                with: Data((bufferedArgs?["settingsJson"] as? String ?? "").utf8)
            ) as? [String: Any]
        XCTAssertEqual(stored?["licenseKey"] as? String, "[redacted]")
        XCTAssertEqual(stored?["enabled"] as? Bool, true)
    }

    // MARK: - sanitize / CWE-117

    func testSanitizeReplacesCRAndLFWithSpacesProducingASingleLineEntry() {
        ScanditLogger.shared.setLevel(.debug)
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: "line1\r\nline2"
        )
        let record = ScanditLogger.shared.getRecentLogs().first!
        let line = ScanditLogger.shared.format(record)
        XCTAssertFalse(line.contains("\r"))
        XCTAssertFalse(line.contains("\n"))
        XCTAssertTrue(line.contains("line1"))
        XCTAssertTrue(line.contains("line2"))
    }

    func testSanitizeStripsControlCharactersFromTheEntry() {
        ScanditLogger.shared.setLevel(.debug)
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: "a\u{0001}b\u{007F}c"
        )
        let record = ScanditLogger.shared.getRecentLogs().first!
        let line = ScanditLogger.shared.format(record)
        XCTAssertFalse(line.contains("\u{0001}"))
        XCTAssertFalse(line.contains("\u{007F}"))
        XCTAssertTrue(line.contains("abc"))
    }

    // MARK: - subscribers

    func testASubscriberReceivesEmittedRecords() {
        ScanditLogger.shared.setLevel(.trace)
        var received: [LogRecord] = []
        track(ScanditLogger.shared.subscribe { received.append($0) })
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        XCTAssertEqual(received.map { $0.message }, ["msg"])
    }

    func testTheReturnedUnsubscribeClosureStopsFurtherDelivery() {
        ScanditLogger.shared.setLevel(.trace)
        var received: [LogRecord] = []
        let unsubscribe = ScanditLogger.shared.subscribe { received.append($0) }
        unsubscribe()
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        XCTAssertTrue(received.isEmpty)
    }

    func testMultipleSubscribersAllReceiveTheSameRecord() {
        ScanditLogger.shared.setLevel(.trace)
        var first: [LogRecord] = []
        var second: [LogRecord] = []
        track(ScanditLogger.shared.subscribe { first.append($0) })
        track(ScanditLogger.shared.subscribe { second.append($0) })
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(second.count, 1)
    }

    func testUnsubscribingAnEarlierSubscriberDoesNotDropLaterOnesTokenNotIndex() {
        // Pins the SDC-31777 defect #2 regression: `subscribe` used to capture
        // the subscriber's array INDEX, so once an earlier subscriber
        // unsubscribed and the array shifted, the wrong callback got removed
        // on the next unsubscribe. It's now token-based
        // (ScanditLogger.swift:46-52,124-136). Subscribe A, B, C; unsubscribe
        // A; both B and C must still fire — neither should be silently
        // dropped by an index that shifted after A left.
        ScanditLogger.shared.setLevel(.trace)
        var aCount = 0
        var bCount = 0
        var cCount = 0
        let unsubscribeA = ScanditLogger.shared.subscribe { _ in aCount += 1 }
        track(ScanditLogger.shared.subscribe { _ in bCount += 1 })
        track(ScanditLogger.shared.subscribe { _ in cCount += 1 })

        unsubscribeA()
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")

        XCTAssertEqual(aCount, 0)
        XCTAssertEqual(bCount, 1)
        XCTAssertEqual(cCount, 1)
    }

    // NOTE: Android's `LoggingCommandTest`-adjacent "a subscriber that throws
    // does not prevent the record reaching the buffer nor other subscribers"
    // has no Swift analog: `subscribe`'s callback type is `(LogRecord) -> Void`,
    // a non-throwing closure, so a subscriber cannot propagate an error the way
    // a Kotlin lambda can throw a RuntimeException.

    // MARK: - thread safety

    func testConcurrentAppendsFromManyThreadsProduceNoLossAndNoDuplication() {
        let threadCount = 8
        let perThread = 100
        ScanditLogger.shared.setLevel(.trace)

        var expected = Set<String>()
        for t in 0..<threadCount {
            for i in 0..<perThread {
                expected.insert("thread-\(t)-msg-\(i)")
            }
        }

        // Every `emit` also formats an ISO8601 line and writes it to os_log, so
        // 1600 emits are I/O-bound, not CPU-bound. A tight deadline turns a
        // loaded CI runner into a red build (job 61381783: 1017/1600 emitted in
        // 5s). This test is about the buffer staying consistent under
        // contention, not about throughput — so the group is waited on without
        // a deadline of our own, and XCTest's per-test timeout remains the
        // backstop against an actual hang.
        let group = DispatchGroup()
        for t in 0..<threadCount {
            DispatchQueue.global().async(group: group) {
                for i in 0..<perThread {
                    ScanditLogger.shared.emit(
                        level: .info,
                        category: .bridge,
                        source: "src",
                        message: "thread-\(t)-msg-\(i)"
                    )
                }
            }
        }
        group.wait()

        let logs = ScanditLogger.shared.getRecentLogs()
        let messages = logs.map { $0.message }
        let seen = Set(messages)

        // Asserted as counts and small sample slices rather than whole-set
        // equality: a failing `XCTAssertEqual(Set(messages), expected)` prints
        // both 1600-element sets, which is unreadable in a test report and, on
        // a verbose job, pushes the real error past GitLab's log cap.
        XCTAssertEqual(messages.count, threadCount * perThread, "record count")
        let missing = expected.subtracting(seen).sorted()
        XCTAssertTrue(missing.isEmpty, "\(missing.count) messages lost, e.g. \(missing.prefix(5))")
        let unexpected = seen.subtracting(expected).sorted()
        XCTAssertTrue(unexpected.isEmpty, "\(unexpected.count) unexpected messages, e.g. \(unexpected.prefix(5))")
        XCTAssertEqual(messages.count, seen.count, "duplicate records in buffer")
        XCTAssertFalse(messages.contains(""))
    }

    // MARK: - LogRecord wire shape

    func testToBridgePayloadKeySetAndIntRawValueSerialization() {
        let record = LogRecord(
            ts: 1234,
            level: .debug,
            category: .bridge,
            source: "src",
            message: "msg",
            fields: ["a": 1],
            durationMs: 5,
            error: LogRecordError(name: "E", message: "m", stack: "s")
        )
        let payload = record.toBridgePayload()
        XCTAssertEqual(
            Set(payload.keys),
            ["ts", "level", "category", "source", "message", "fields", "durationMs", "error"]
        )
        XCTAssertEqual(payload["level"] as? Int, LogLevel.debug.rawValue)
        XCTAssertEqual(payload["category"] as? Int, LogCategory.bridge.rawValue)
    }

    func testToBridgePayloadKeepsAllKeysPresentEvenWhenDurationMsErrorAndFieldsAreNil() {
        let record = LogRecord(ts: 1234, level: .info, category: .lifecycle, source: "src", message: "msg")
        let payload = record.toBridgePayload()

        XCTAssertEqual(
            Set(payload.keys),
            ["ts", "level", "category", "source", "message", "fields", "durationMs", "error"]
        )
        XCTAssertNil(payload["durationMs"] as? Int64)
        XCTAssertNil(payload["error"] as? [String: Any?])
        XCTAssertNil(payload["fields"] as? [String: Any?])
    }
}
