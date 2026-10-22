/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

/// Specs for the batching path that ships records to the JS/Dart layer:
/// `ScanditLogger.queueForBatch` / `flushPending` / `shipBatch`.
///
/// Two boundaries govern it: a 50-record batch that ships inline on the
/// record that fills it, and a 100 ms scheduled flush for anything below
/// that. The flush queue is private and not injectable, so the timed
/// assertions await an `XCTestExpectation` the recording emitter fulfills
/// rather than sleeping for a fixed period — see `elapsedMsSince` below for
/// why even the unconditional/conditional split exists.
final class BatchEmitTests: XCTestCase {
    private static let batchEvent = "ScanditLogger.batch"
    private static let batchMaxRecords = 50
    private static let batchFlushIntervalMs: Double = 100
    private static let awaitSeconds: TimeInterval = 2

    override func setUp() {
        super.setUp()
        ScanditLoggerTestSupport.resetLogger()
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.all)
    }

    override func tearDown() {
        // Detach first, then wait out the flush interval: detaching does NOT
        // cancel an already-scheduled flush, and a stale work item firing during
        // the next test would ship its partial batch — exactly what the boundary
        // assertions below rule out. See `drainScheduledFlush`.
        ScanditLoggerTestSupport.resetLogger()
        ScanditLoggerTestSupport.drainScheduledFlush(self)
        super.tearDown()
    }

    private func emitRecords(_ count: Int, prefix: String = "msg") {
        for i in 1...count {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "\(prefix)-\(i)")
        }
    }

    private func messages(of records: [[String: Any?]]) -> [String] {
        records.map { $0["message"] as? String ?? "" }
    }

    /// Wall-clock cost of the emit loop just executed.
    ///
    /// `queueForBatch` schedules the flush `batchFlushIntervalMs` after the
    /// FIRST record of a batch, so any "nothing has shipped yet" observation
    /// is only valid if the whole loop finished inside that window. On a
    /// loaded CI runner a scheduling hiccup can push even a fast loop past
    /// 100 ms, at which point the timer ships a partial batch and a bare
    /// "nothing shipped yet" assertion would fail on a perfectly correct
    /// implementation. So the delivery guarantees (everything arrives, in
    /// order, no batch over the boundary) are asserted unconditionally, and
    /// the inline-vs-timer half is asserted only when this returns a value
    /// below the interval.
    private func elapsedMs(since start: DispatchTime) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
    }

    private func assertNoBatchExceedsBoundary(_ emitter: RecordingEmitter) {
        for batch in emitter.batches {
            XCTAssertLessThanOrEqual(batch.count, Self.batchMaxRecords)
        }
    }

    // MARK: - no emitter

    func testWithoutARegisteredEmitterRecordsAreStillBuffered() {
        // No emitter is attached, so "nothing was shipped" has nothing to observe
        // it with — that half of the claim belongs to
        // `testDetachingTheEmitterDiscardsPendingRecordsInsteadOfFlushingThem`,
        // which holds a RecordingEmitter and can assert it. Here we pin only that
        // the absent emitter does not stop records reaching the ring buffer.
        emitRecords(Self.batchMaxRecords + 10)
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().count, Self.batchMaxRecords + 10)
    }

    // MARK: - the 50-record boundary

    func testTheFiftiethRecordShipsOneBatchOfFiftySynchronously() {
        let emitter = RecordingEmitter(target: Self.batchMaxRecords)
        ScanditLogger.shared.registerEmitter(emitter)

        let start = DispatchTime.now()
        emitRecords(Self.batchMaxRecords)
        let batchesAfterLoop = emitter.batches
        let elapsed = elapsedMs(since: start)

        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        XCTAssertEqual(emitter.shippedCount, Self.batchMaxRecords)
        assertNoBatchExceedsBoundary(emitter)

        if elapsed < Self.batchFlushIntervalMs {
            XCTAssertEqual(batchesAfterLoop.count, 1)
            XCTAssertEqual(batchesAfterLoop.first?.count, Self.batchMaxRecords)
        }
    }

    func testAShippedBatchCarriesItsRecordsUnderTheRecordsKey() {
        let emitter = RecordingEmitter(target: Self.batchMaxRecords)
        ScanditLogger.shared.registerEmitter(emitter)

        emitRecords(Self.batchMaxRecords)

        // Await the latch rather than reading straight after the loop: a
        // mid-loop timer flush would ship a partial batch and leave the
        // remainder for the next tick. Ordering is FIFO either way.
        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        XCTAssertEqual(messages(of: emitter.records), (1...Self.batchMaxRecords).map { "msg-\($0)" })
    }

    // MARK: - the 100 ms boundary

    func testASingleRecordIsNotShippedInlineAndArrivesOnTheScheduledFlush() {
        // This is the reliable home for the "sub-boundary records wait for
        // the timer" claim: one emit takes microseconds against a 100 ms
        // interval, so the observation window is never in doubt — unlike a
        // 49-record loop.
        let emitter = RecordingEmitter(target: 1)
        ScanditLogger.shared.registerEmitter(emitter)

        let start = DispatchTime.now()
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "only-one")
        let shippedBeforeAwait = emitter.shippedCount
        let elapsed = elapsedMs(since: start)

        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        XCTAssertEqual(emitter.shippedCount, 1)
        XCTAssertEqual(messages(of: emitter.records), ["only-one"])
        if elapsed < Self.batchFlushIntervalMs {
            XCTAssertEqual(shippedBeforeAwait, 0)
        }
    }

    func testFortyNineRecordsShipNothingSynchronouslyAndAreFlushedByTheTimer() {
        let emitter = RecordingEmitter(target: Self.batchMaxRecords - 1)
        ScanditLogger.shared.registerEmitter(emitter)

        let start = DispatchTime.now()
        emitRecords(Self.batchMaxRecords - 1)
        let shippedBeforeAwait = emitter.shippedCount
        let elapsed = elapsedMs(since: start)

        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        XCTAssertEqual(emitter.shippedCount, Self.batchMaxRecords - 1)
        XCTAssertEqual(messages(of: emitter.records), (1...Self.batchMaxRecords - 1).map { "msg-\($0)" })
        assertNoBatchExceedsBoundary(emitter)
        if elapsed < Self.batchFlushIntervalMs {
            XCTAssertEqual(shippedBeforeAwait, 0)
        }
    }

    func testFiftyOneRecordsShipFiftyInlineAndTheRemainderOnTheTimer() {
        let emitter = RecordingEmitter(target: Self.batchMaxRecords + 1)
        ScanditLogger.shared.registerEmitter(emitter)

        let start = DispatchTime.now()
        emitRecords(Self.batchMaxRecords + 1)
        let shippedBeforeAwait = emitter.shippedCount
        let firstBatchSize = emitter.batches.first?.count
        let elapsed = elapsedMs(since: start)

        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        XCTAssertEqual(emitter.shippedCount, Self.batchMaxRecords + 1)
        assertNoBatchExceedsBoundary(emitter)
        if elapsed < Self.batchFlushIntervalMs {
            XCTAssertEqual(shippedBeforeAwait, Self.batchMaxRecords)
            XCTAssertEqual(firstBatchSize, Self.batchMaxRecords)
        }
    }

    // MARK: - burst

    func testABurstOfRecordsShipsEveryRecordExactlyOnce() {
        let total = 250
        let emitter = RecordingEmitter(target: total)
        ScanditLogger.shared.registerEmitter(emitter)

        emitRecords(total, prefix: "burst")

        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        let shippedMessages = messages(of: emitter.records)
        XCTAssertEqual(shippedMessages.count, total)
        XCTAssertEqual(Set(shippedMessages), Set((1...total).map { "burst-\($0)" }))
        XCTAssertEqual(shippedMessages.count, Set(shippedMessages).count)
    }

    // MARK: - teardown

    func testDetachingTheEmitterDiscardsPendingRecordsInsteadOfFlushingThem() {
        // NOTE: this pins ACTUAL behaviour, which is the opposite of what
        // SDC-33100's acceptance criteria describe ("batches flush on
        // shutdown"). There is no flush()/shutdown() entry point; the only
        // teardown is registerEmitter(nil) (ScanditLogger.swift:149-157). It
        // clears `pendingBatch` and marks no flush scheduled; the already-queued
        // flush is NOT cancelled, it simply finds a nil emitter and no-ops. So
        // anything queued below the 50-record boundary is DISCARDED rather
        // than shipped. Reported on the ticket as a likely defect worth its
        // own fix (Android has the identical bug, also unticketed); do not
        // "correct" this assertion to expect a flush until the implementation
        // actually does one. A short sleep is acceptable here only because
        // the assertion is a negative — that nothing arrives after the flush
        // interval elapses.
        let emitter = RecordingEmitter()
        ScanditLogger.shared.registerEmitter(emitter)
        let start = DispatchTime.now()
        emitRecords(5)
        let shippedBeforeDetach = emitter.shippedCount
        let elapsed = elapsedMs(since: start)

        ScanditLogger.shared.registerEmitter(nil)
        let noFlushArrived = expectation(description: "nothing ships after detach")
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(Self.batchFlushIntervalMs) * 3)) {
            noFlushArrived.fulfill()
        }
        wait(for: [noFlushArrived], timeout: Self.awaitSeconds)

        XCTAssertEqual(emitter.shippedCount, shippedBeforeDetach)
        if elapsed < Self.batchFlushIntervalMs {
            XCTAssertEqual(shippedBeforeDetach, 0)
        }
    }

    // MARK: - payload shape

    func testAShippedRecordKeepsItsIdsButNotItsArgsWhileTheLocalBufferKeepsBoth() {
        let emitter = RecordingEmitter(target: 1)
        ScanditLogger.shared.registerEmitter(emitter)

        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "ios.CoreModule",
            message: "someMethod",
            fields: ["modeId": 3, "args": ["settingsJson": "{}"]]
        )

        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        let shipped = emitter.records[0]["fields"] as? [String: Any?]
        XCTAssertEqual(shipped?.count, 1)
        XCTAssertEqual(shipped?["modeId"] as? Int, 3)
        XCTAssertNotNil(ScanditLogger.shared.getRecentLogs()[0].fields?["args"] as? [String: Any?])
    }

    func testAShippedRecordCarriesTheBridgePayloadShapeWithLevelAsAnIntRank() {
        let emitter = RecordingEmitter(target: 1)
        ScanditLogger.shared.registerEmitter(emitter)

        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "ios.CoreModule",
            message: "someMethod",
            fields: ["modeId": 3],
            durationMs: 12,
            error: LogRecordError(name: "Boom", message: "went wrong", stack: "stack-trace")
        )

        wait(for: [emitter.allShipped], timeout: Self.awaitSeconds)
        let record = emitter.records[0]
        XCTAssertEqual(
            Set(record.keys),
            ["ts", "level", "category", "source", "message", "fields", "durationMs", "error"]
        )
        XCTAssertEqual(record["level"] as? Int, LogLevel.debug.rawValue)
        XCTAssertEqual(record["category"] as? Int, LogCategory.bridge.rawValue)
        XCTAssertEqual(record["source"] as? String, "ios.CoreModule")
        XCTAssertEqual(record["message"] as? String, "someMethod")
        let fields = record["fields"] as? [String: Any?]
        XCTAssertEqual(fields?["modeId"] as? Int, 3)
        XCTAssertEqual(record["durationMs"] as? Int64, 12)
        XCTAssertNotNil(record["ts"] as? Int64)

        let error = record["error"] as? [String: Any?]
        XCTAssertEqual(error?["name"] as? String, "Boom")
        XCTAssertEqual(error?["message"] as? String, "went wrong")
        XCTAssertEqual(error?["stack"] as? String, "stack-trace")
    }

    // NOTE: Android's "an emitter that throws does not propagate and the
    // logger keeps shipping later batches" has no Swift analog: `Emitter.emit`
    // (Event/Emitter.swift) is a non-throwing method, so there is no throwing
    // path for `shipBatch` to swallow.
}
