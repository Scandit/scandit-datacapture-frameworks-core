/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class CoreModuleLogCommandsTests: XCTestCase {
    private static let settleTimeout: TimeInterval = 5

    private var root: URL!
    private var logDirectory: URL { root.appendingPathComponent("Scandit/Logs") }

    override func setUp() {
        super.setUp()
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        ScanditLoggerTestSupport.resetLogger()
        ScanditLogger.shared.setLogDirectory(logDirectory)
    }

    override func tearDown() {
        ScanditLoggerTestSupport.resetLogger()
        ScanditLoggerTestSupport.drainScheduledFlush(self)
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    /// Batch emits run on the logger's file queue, so a blocked emit holds that queue.
    private final class FileQueueGate: Emitter {
        let entered = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)

        func emit(name: String, payload: [String: Any?]) {
            entered.signal()
            _ = release.wait(timeout: .now() + CoreModuleLogCommandsTests.settleTimeout)
        }

        func hasListener(for event: String) -> Bool { false }
        func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool { false }
        func hasModeSpecificListenersForEvent(_ modeId: Int, for event: String) -> Bool { false }
    }

    private func occupyFileQueue() -> FileQueueGate {
        let gate = FileQueueGate()
        ScanditLogger.shared.registerEmitter(gate)
        ScanditLogger.shared.setLevel(.info)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "holds-the-file-queue")
        XCTAssertEqual(gate.entered.wait(timeout: .now() + Self.settleTimeout), .success)
        return gate
    }

    private func settle(_ result: FakeFrameworksResult) {
        wait(for: [result.settled], timeout: Self.settleTimeout)
    }

    func testAppendLogsStoresTheLinesVerbatimAndIsInterceptedBeforeTheCommandFactory() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()
        let method = FakeMethodCall(method: "appendLogs", args: ["lines": "{\"a\":1}\n{\"b\":2}"])

        let handled = module.execute(method, result: result, module: fwModule)
        ScanditLogger.shared.flushLogFile()

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 0)
        XCTAssertTrue(result.successCalled)
        XCTAssertEqual(RollingLogFile(directory: logDirectory).readAll(), "{\"a\":1}\n{\"b\":2}\n")
    }

    func testAppendLogsWithoutLinesRejectsWithAppendLogsError() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let result = FakeFrameworksResult()

        _ = module.execute(FakeMethodCall(method: "appendLogs"), result: result, module: FakeFrameworkModule())

        XCTAssertTrue(result.rejectCalled)
        XCTAssertEqual(result.rejectCode, "AppendLogsError")
    }

    func testClearLogsEmptiesTheRingBufferAndDeletesTheStoredFiles() {
        ScanditLogger.shared.setLevel(.info)
        ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "kept-in-memory")
        ScanditLogger.shared.flushLogFile()
        let module = CoreModule.create(emitter: RecordingEmitter())
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        let handled = module.execute(FakeMethodCall(method: "clearLogs"), result: result, module: fwModule)
        settle(result)

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 0)
        XCTAssertTrue(result.successCalled)
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
        XCTAssertEqual(RollingLogFile(directory: logDirectory).readAll(), "")
    }

    func testClearLogsReturnsWhileTheFileQueueIsBusyAndSettlesOnceItIsFree() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let gate = occupyFileQueue()
        let result = FakeFrameworksResult()

        _ = module.execute(FakeMethodCall(method: "clearLogs"), result: result, module: FakeFrameworkModule())
        let settledEarly = result.successCalled || result.rejectCalled
        gate.release.signal()
        settle(result)

        XCTAssertFalse(settledEarly)
        XCTAssertTrue(result.successCalled)
    }

    func testWriteLogsReturnsWhileTheFileQueueIsBusyAndSettlesWithTheExportedPath() throws {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let gate = occupyFileQueue()
        let result = FakeFrameworksResult()
        let destination = root.appendingPathComponent("out.jsonl")
        let method = FakeMethodCall(method: "writeLogs", args: ["header": "{}", "path": destination.path])

        _ = module.execute(method, result: result, module: FakeFrameworkModule())
        let settledEarly = result.successCalled || result.rejectCalled
        gate.release.signal()
        settle(result)

        XCTAssertFalse(settledEarly)
        XCTAssertEqual(result.successResult as? String, destination.path)
        let lines = try String(contentsOf: destination, encoding: .utf8).split(separator: "\n")
        let header = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(lines[0].utf8)) as? [String: Any])
        XCTAssertEqual(header["recordCount"] as? Int, 1)
        XCTAssertTrue(lines[1].contains("holds-the-file-queue"))
    }

    func testLogStorageSetUpAtStartReachesFilesFromAnEarlierRunWhileTheLevelIsOff() throws {
        ScanditLogger.shared.setLogDirectory(nil)
        let applicationSupport = root.appendingPathComponent("Application Support")
        let earlierDirectory = applicationSupport.appendingPathComponent("Scandit/Logs")
        try FileManager.default.createDirectory(at: earlierDirectory, withIntermediateDirectories: true)
        let earlier = earlierDirectory.appendingPathComponent(RollingLogFile.currentName)
        try "{\"message\":\"from-an-earlier-run\"}\n".write(to: earlier, atomically: true, encoding: .utf8)

        CoreModule.configureLogStorage(
            applicationSupport: applicationSupport,
            caches: root.appendingPathComponent("Caches")
        )
        defer { ScanditLogger.shared.setExportFile(nil) }
        let result = FakeFrameworksResult()
        _ = CoreModule.create(emitter: RecordingEmitter()).execute(
            FakeMethodCall(method: "clearLogs"),
            result: result,
            module: FakeFrameworkModule()
        )
        settle(result)

        XCTAssertFalse(FileManager.default.fileExists(atPath: earlier.path))
    }

    func testClearLogsAlsoDeletesTheDefaultExportFile() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let export = root.appendingPathComponent("scandit-debug-log.jsonl")
        try "x".write(to: export, atomically: true, encoding: .utf8)
        ScanditLogger.shared.setExportFile(export)
        defer { ScanditLogger.shared.setExportFile(nil) }
        let result = FakeFrameworksResult()

        _ = CoreModule.create(emitter: RecordingEmitter()).execute(
            FakeMethodCall(method: "clearLogs"),
            result: result,
            module: FakeFrameworkModule()
        )
        settle(result)

        XCTAssertFalse(FileManager.default.fileExists(atPath: export.path))
    }
}
