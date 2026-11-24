/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class ScanditLoggerFileTests: XCTestCase {
    private static let raceRounds = 300
    private var root: URL!
    private var logDirectory: URL { root.appendingPathComponent("Scandit/Logs") }

    override func setUp() {
        super.setUp()
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        ScanditLoggerTestSupport.resetLogger()
        ScanditLogger.shared.setLevel(.trace)
    }

    override func tearDown() {
        ScanditLoggerTestSupport.resetLogger()
        ScanditLoggerTestSupport.drainScheduledFlush(self)
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    private func stored() -> [[String: Any]] {
        RollingLogFile(directory: logDirectory).readAll()
            .split(separator: "\n")
            .compactMap { try? JSONSerialization.jsonObject(with: Data($0.utf8)) as? [String: Any] }
    }

    private func awaitStoredLines(_ count: Int, timeout: TimeInterval = 2) -> Int {
        let deadline = Date().addingTimeInterval(timeout)
        while stored().count < count && Date() < deadline { Thread.sleep(forTimeInterval: 0.01) }
        return stored().count
    }

    func testANonFiniteNumberInTheFieldsIsStoredAsTextInsteadOfBreakingTheLine() throws {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "ios.Core",
            message: "zoom",
            fields: ["factor": Double.nan, "kept": 2]
        )
        ScanditLogger.shared.flushLogFile()

        let fields = try XCTUnwrap(stored().first?["fields"] as? [String: Any])
        XCTAssertEqual(fields["factor"] as? String, "nan")
        XCTAssertEqual(fields["kept"] as? Int, 2)
    }

    func testARecordEmittedWithALogDirectorySetLandsInTheRollingFileAsAJSONLine() throws {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "ios.Core",
            message: "doThing",
            durationMs: 7
        )
        ScanditLogger.shared.flushLogFile()

        let line = try XCTUnwrap(stored().first)
        XCTAssertEqual(line["message"] as? String, "doThing")
        XCTAssertEqual(line["level"] as? String, "DEBUG")
        XCTAssertEqual(line["category"] as? String, "Bridge")
        XCTAssertEqual(line["source"] as? String, "ios.Core")
        XCTAssertEqual(line["durationMs"] as? Int, 7)
        XCTAssertTrue((line["time"] as? String)?.hasSuffix("Z") == true)
    }

    func testASingleRecordIsWrittenWithinTheFlushIntervalWithoutAnExplicitFlush() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "lonely")
        XCTAssertEqual(awaitStoredLines(1), 1)
    }

    func testFiftyRecordsAreAllWritten() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        (0..<50).forEach {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "m-\($0)")
        }
        XCTAssertEqual(awaitStoredLines(50), 50)
        XCTAssertEqual(stored().compactMap { $0["message"] as? String }, (0..<50).map { "m-\($0)" })
    }

    func testWithoutALogDirectoryNothingIsWritten() {
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "m")
        ScanditLogger.shared.flushLogFile()
        XCTAssertFalse(FileManager.default.fileExists(atPath: logDirectory.path))
    }

    func testArgsAreRedactedInTheStoredLine() throws {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: "m",
            fields: ["args": ["licenseKey": "secret", "units": "mm"]]
        )
        ScanditLogger.shared.flushLogFile()

        let fields = try XCTUnwrap(stored().first?["fields"] as? [String: Any])
        let args = try XCTUnwrap(fields["args"] as? [String: Any])
        XCTAssertEqual(args["licenseKey"] as? String, "[redacted]")
        XCTAssertEqual(args["units"] as? String, "mm")
    }

    func testGoingToLevelOffFlushesWhatIsPendingAndStopsFurtherWrites() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "before")
        ScanditLogger.shared.setLevel(.off)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "after")
        ScanditLogger.shared.flushLogFile()
        XCTAssertEqual(stored().compactMap { $0["message"] as? String }, ["before"])
    }

    func testFilesPersistWhenTheLoggerIsPointedAtTheSameDirectoryAgain() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "first")
        ScanditLogger.shared.flushLogFile()
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "second")
        ScanditLogger.shared.flushLogFile()
        XCTAssertEqual(stored().compactMap { $0["message"] as? String }, ["first", "second"])
    }

    func testAppendLinesStoresTheTextVerbatim() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.appendLines("{\"a\":1}\n{\"b\":2}")
        ScanditLogger.shared.flushLogFile()
        XCTAssertEqual(RollingLogFile(directory: logDirectory).readAll(), "{\"a\":1}\n{\"b\":2}\n")
    }

    func testDeleteLogFilesRemovesTheStoredRecordsAndDropsThePendingOnes() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "stored")
        ScanditLogger.shared.flushLogFile()
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "pending")
        ScanditLogger.shared.deleteLogFiles {}
        ScanditLogger.shared.flushLogFile()
        XCTAssertEqual(RollingLogFile(directory: logDirectory).readAll(), "")
    }

    func testAFullBatchTakenWhileDeleteLogFilesRunsOnAnotherThreadDoesNotOutliveTheDelete() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        for round in 0..<Self.raceRounds {
            for index in 0..<ScanditLogger.batchMaxRecords - 1 {
                ScanditLogger.shared.emit(
                    level: .info,
                    category: .bridge,
                    source: "src",
                    message: "old-\(round)-\(index)"
                )
            }
            // The clearer spins rather than sleeps, then waits a varying few cycles, so across
            // rounds its delete lands inside the emitting thread's take-then-enqueue window.
            let boundaryReached = SpinFlag()
            let deleted = DispatchSemaphore(value: 0)
            let jitter = round % 64
            let clearer = Thread {
                while !boundaryReached.isSet {}
                for _ in 0..<(jitter * 8) { _ = boundaryReached.isSet }
                ScanditLogger.shared.deleteLogFiles { deleted.signal() }
            }
            clearer.start()
            let unsubscribe = ScanditLogger.shared.subscribe { _ in boundaryReached.set() }
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "boundary-\(round)")
            unsubscribe()
            XCTAssertEqual(deleted.wait(timeout: .now() + 2), .success)
            ScanditLogger.shared.flushLogFile()

            let survivors = stored().compactMap { $0["message"] as? String }.filter { $0.hasPrefix("old-") }
            XCTAssertEqual(survivors, [], "round \(round)")
            if !survivors.isEmpty { return }
            let cleaned = DispatchSemaphore(value: 0)
            ScanditLogger.shared.deleteLogFiles { cleaned.signal() }
            XCTAssertEqual(cleaned.wait(timeout: .now() + 2), .success)
        }
    }

    func testReadLogFilesReturnsAppendedLinesAndNativeRecordsInWriteOrder() {
        ScanditLogger.shared.setLogDirectory(logDirectory)
        ScanditLogger.shared.appendLines("{\"message\":\"from-ts\"}")
        ScanditLogger.shared.emit(level: .debug, category: .bridge, source: "ios.Core", message: "from-native")

        let messages = readLogFiles()
            .split(separator: "\n")
            .compactMap { try? JSONSerialization.jsonObject(with: Data($0.utf8)) as? [String: Any] }
            .compactMap { $0["message"] as? String }

        XCTAssertEqual(messages, ["from-ts", "from-native"])
    }

    func testReadLogFilesIsEmptyWhenNothingWasLogged() {
        ScanditLogger.shared.setLogDirectory(logDirectory)

        XCTAssertEqual(readLogFiles(), "")
    }

    private func readLogFiles() -> String {
        let read = expectation(description: "log files read")
        var contents = ""
        ScanditLogger.shared.readLogFiles {
            contents = $0
            read.fulfill()
        }
        wait(for: [read], timeout: 2)
        return contents
    }
}

private final class SpinFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var isSet: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set() {
        lock.lock()
        value = true
        lock.unlock()
    }
}
