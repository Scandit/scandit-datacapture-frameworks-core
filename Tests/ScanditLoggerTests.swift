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
        // of configuration (ScanditLogger.swift:170), before the level/category
        // gates even run.
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.all)
        ScanditLogger.shared.emit(level: .off, category: .bridge, source: "src", message: "msg")
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    // MARK: - category masking

    func testCategoryBitAbsentFromTheMaskIsDropped() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.bridge)
        ScanditLogger.shared.emit(level: .info, category: .listener, source: "src", message: "msg")
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    func testCategoryBitPresentInTheMaskIsKept() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.bridge)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().count, 1)
    }

    func testDefaultsCategoryMaskDropsEvents() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.defaults)
        ScanditLogger.shared.emit(level: .info, category: .events, source: "src", message: "msg")
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    func testAllCategoryMaskAdmitsEvents() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.all)
        ScanditLogger.shared.emit(level: .info, category: .events, source: "src", message: "msg")
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().count, 1)
    }

    func testMultiBitCategoryArgumentIsDroppedUnlessTheMaskContainsEveryBit() {
        // Swift-specific: `LogCategory` is an `OptionSet`, and
        // `configuredCategories.contains(category)` requires the mask to
        // contain ALL bits set in `category`, not merely share one — the
        // opposite of Android's bitwise-AND-any-bit semantics. A multi-bit
        // category argument against a single-bit mask is therefore dropped.
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.bridge)
        ScanditLogger.shared.emit(
            level: .info,
            category: [.bridge, .events],
            source: "src",
            message: "msg"
        )
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    func testMultiBitCategoryArgumentIsKeptWhenTheMaskContainsEveryBit() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.all)
        ScanditLogger.shared.emit(
            level: .info,
            category: [.bridge, .events],
            source: "src",
            message: "msg"
        )
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().count, 1)
    }

    func testSetCategoriesOfEmptyMaskDropsEverything() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories([])
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
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
        XCTAssertEqual(LogCategory.defaults.name, "Unknown")
        XCTAssertEqual(LogCategory.all.name, "Unknown")
        XCTAssertEqual(LogCategory(rawValue: 0).name, "Unknown")
        XCTAssertEqual(LogCategory(rawValue: 1 << 10).name, "Unknown")
    }

    // MARK: - ring buffer

    func testBelowCapacityKeepsAllRecordsInOldestFirstInsertionOrder() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setBufferSize(10)
        (1...5).forEach {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg-\($0)")
        }
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, (1...5).map { "msg-\($0)" })
    }

    func testExactlyAtCapacityKeepsAllRecords() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setBufferSize(5)
        (1...5).forEach {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg-\($0)")
        }
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, (1...5).map { "msg-\($0)" })
    }

    func testBeyondCapacityEvictsTheOldestAndKeepsExactlyBufferSizeRecords() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setBufferSize(3)
        (1...5).forEach {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg-\($0)")
        }
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, ["msg-3", "msg-4", "msg-5"])
    }

    func testRingBufferPreservesOldestToNewestOrderAfterWrappingMoreThanTwice() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setBufferSize(4)
        (1...11).forEach {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg-\($0)")
        }
        let messages = ScanditLogger.shared.getRecentLogs().map { $0.message }
        XCTAssertEqual(messages, ["msg-8", "msg-9", "msg-10", "msg-11"])
    }

    // MARK: - setBufferSize

    func testSetBufferSizeClampsZeroToAMinimumOfOne() {
        ScanditLogger.shared.setBufferSize(0)
        XCTAssertEqual(ScanditLogger.shared.getBufferSize(), 1)
    }

    func testSetBufferSizeClampsANegativeSizeToAMinimumOfOne() {
        ScanditLogger.shared.setBufferSize(-5)
        XCTAssertEqual(ScanditLogger.shared.getBufferSize(), 1)
    }

    func testChangingTheBufferSizeResetsTheBufferContents() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setBufferSize(5)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        ScanditLogger.shared.setBufferSize(10)
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    func testSettingTheSameBufferSizeIsANoOpThatPreservesContents() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setBufferSize(5)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        ScanditLogger.shared.setBufferSize(5)
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().map { $0.message }, ["msg"])
    }

    func testGetBufferSizeReflectsTheConfiguredSize() {
        ScanditLogger.shared.setBufferSize(7)
        XCTAssertEqual(ScanditLogger.shared.getBufferSize(), 7)
    }

    // MARK: - clear

    func testClearEmptiesTheBuffer() {
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg")
        ScanditLogger.shared.clear()
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    // MARK: - os_log privacy (platformLogLine seam)

    func testPlatformLogLineOmitsArgsWholesaleWhileGetRecentLogsAndFormatKeepThem() {
        // NOTE: key-level redaction of `licenseKey` (and any customer-configured
        // redacted key) happens on the TS side only, in `ScanditLogger.ingest`.
        // Native is never told the customer-configured key set, so instead of
        // attempting (and failing) to redact specific keys, it omits
        // `fields["args"]` wholesale from anything written to the platform
        // logger — see the doc comment on `platformLogLine`, which is the one
        // place that decision lives. This is a deliberate asymmetry, not a
        // bug: `getRecentLogs()` and `format()` still carry the full `fields`
        // map, including `args`, for local diagnostic use. SDC-33094 owns
        // bringing native redaction to parity with the TS side — do not turn
        // this test into an assertion that iOS redacts `licenseKey`, it does
        // not.
        ScanditLogger.shared.setLevel(.debug)
        ScanditLogger.shared.setCategories(.bridge)
        let fields: [String: Any?] = [
            "modeId": 7,
            "args": ["licenseKey": "SECRET-KEY-VALUE"],
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
        XCTAssertFalse(logLine.contains("SECRET-KEY-VALUE"))
        XCTAssertFalse(logLine.contains("args"))
        XCTAssertTrue(logLine.contains("modeId"))

        XCTAssertTrue(ScanditLogger.shared.format(record).contains("SECRET-KEY-VALUE"))
    }

    func testALicenseKeyInsideAJSONStringArgValueIsOmittedFromTheLogLineButKeptVerbatimInTheBuffer() {
        // NOTE: SDC-33100's acceptance criteria ask for redaction of configured
        // keys "including inside JSON-string values". iOS implements NO
        // key-level redaction at all (see the note on the test above), so there
        // is certainly none that reaches inside a serialized JSON string. This
        // test pins that reality explicitly: the value is kept out of the
        // platform log only because it sits under `args`, which is dropped
        // wholesale, and it survives UNREDACTED in the ring buffer. If
        // SDC-33094 later brings real redaction to the native side, the second
        // half of this test is the one that must change.
        ScanditLogger.shared.setLevel(.debug)
        ScanditLogger.shared.setCategories(.bridge)
        let settingsJson = #"{"licenseKey":"SECRET-INSIDE-JSON","enabled":true}"#
        let innerArgs: [String: Any?] = ["settingsJson": settingsJson]
        let fields: [String: Any?] = ["args": innerArgs]
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: "msg",
            fields: fields
        )
        let record = ScanditLogger.shared.getRecentLogs().first!

        let logLine = ScanditLogger.shared.platformLogLine(record)
        XCTAssertFalse(logLine.contains("SECRET-INSIDE-JSON"))
        XCTAssertFalse(logLine.contains("settingsJson"))

        let bufferedArgs = ScanditLogger.shared.getRecentLogs().first?.fields?["args"] as? [String: Any?]
        XCTAssertEqual(bufferedArgs?["settingsJson"] as? String, settingsJson)
    }

    // MARK: - sanitize / CWE-117

    func testSanitizeReplacesCRAndLFWithSpacesProducingASingleLineEntry() {
        ScanditLogger.shared.setLevel(.debug)
        ScanditLogger.shared.setCategories(.bridge)
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
        ScanditLogger.shared.setCategories(.bridge)
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
        let perThread = 200
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setBufferSize(threadCount * perThread + 10)

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
