/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class LoggingCommandTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ScanditLoggerTestSupport.resetLogger()
        // Logging fully open by default: this class covers what LoggingCommand
        // records, not the level/category gating (that's ScanditLoggerTests).
        // The setLoggerConfig tests below reconfigure via the call under test.
        ScanditLogger.shared.setLevel(.trace)
        ScanditLogger.shared.setCategories(.all)
    }

    override func tearDown() {
        // The CoreModule specs below attach a real emitter, so this class must
        // also drain the scheduled flush — see `drainScheduledFlush`.
        ScanditLoggerTestSupport.resetLogger()
        ScanditLoggerTestSupport.drainScheduledFlush(self)
        super.tearDown()
    }

    // MARK: - instrumented result identity & forwarding

    func testDelegateIsInvokedWithAnInstrumentedResultNotTheCallersInstance() {
        let callerResult = FakeFrameworksResult()
        var forwarded: FrameworksResult?
        let delegate = BlockCommand { result in forwarded = result }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))

        sut.execute(result: callerResult)

        XCTAssertNotNil(forwarded)
        XCTAssertNotEqual(ObjectIdentifier(forwarded! as AnyObject), ObjectIdentifier(callerResult))
    }

    func testInstrumentedResultForwardsSuccessWithTheIdenticalArgument() {
        let callerResult = FakeFrameworksResult()
        var forwarded: FrameworksResult?
        let delegate = BlockCommand { result in forwarded = result }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))
        sut.execute(result: callerResult)

        forwarded?.success(result: "payload")

        XCTAssertTrue(callerResult.successCalled)
        XCTAssertEqual(callerResult.successResult as? String, "payload")
    }

    func testInstrumentedResultForwardsSuccessAndKeepCallbackWithTheIdenticalArgument() {
        let callerResult = FakeFrameworksResult()
        var forwarded: FrameworksResult?
        let delegate = BlockCommand { result in forwarded = result }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))
        sut.execute(result: callerResult)

        forwarded?.successAndKeepCallback(result: "payload")

        XCTAssertTrue(callerResult.keepCallbackCalled)
        XCTAssertEqual(callerResult.keepCallbackResult as? String, "payload")
    }

    func testInstrumentedResultForwardsRejectWithTheIdenticalArguments() {
        let callerResult = FakeFrameworksResult()
        var forwarded: FrameworksResult?
        let delegate = BlockCommand { result in forwarded = result }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))
        sut.execute(result: callerResult)

        forwarded?.reject(code: "code", message: "message", details: "details")

        XCTAssertTrue(callerResult.rejectCalled)
        XCTAssertEqual(callerResult.rejectCode, "code")
        XCTAssertEqual(callerResult.rejectMessage, "message")
        XCTAssertEqual(callerResult.rejectDetails as? String, "details")
    }

    func testInstrumentedResultForwardsRejectErrorUsingTheNSErrorDomainAndLocalizedDescription() {
        let callerResult = FakeFrameworksResult()
        var forwarded: FrameworksResult?
        let delegate = BlockCommand { result in forwarded = result }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))
        sut.execute(result: callerResult)

        let error = NSError(domain: "com.scandit.test", code: 42, userInfo: [NSLocalizedDescriptionKey: "boom"])
        forwarded?.reject(error: error)

        XCTAssertTrue(callerResult.rejectCalled)
        XCTAssertEqual(callerResult.rejectCode, "com.scandit.test")
        XCTAssertEqual(callerResult.rejectMessage, "boom")

        let record = ScanditLogger.shared.getRecentLogs()[0]
        XCTAssertEqual(record.category, .bridge)
        XCTAssertEqual(record.level, .error)
        XCTAssertEqual(record.error?.name, "com.scandit.test")
        XCTAssertEqual(record.error?.message, "boom")
        XCTAssertNil(record.error?.stack)
    }

    func testInstrumentedResultForwardsAllSixCallbackRegistrationMethodsWithIdenticalArguments() {
        let callerResult = FakeFrameworksResult()
        var forwarded: FrameworksResult?
        let delegate = BlockCommand { result in forwarded = result }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))
        sut.execute(result: callerResult)

        forwarded?.registerCallbackForEvents(["a"])
        forwarded?.unregisterCallbackForEvents(["b"])
        forwarded?.registerModeSpecificCallback(1, eventNames: ["c"])
        forwarded?.unregisterModeSpecificCallback(2, eventNames: ["d"])
        forwarded?.registerViewSpecificCallback(3, eventNames: ["e"])
        forwarded?.unregisterViewSpecificCallback(4, eventNames: ["f"])

        XCTAssertEqual(callerResult.registeredEventNames, ["a"])
        XCTAssertEqual(callerResult.unregisteredEventNames, ["b"])
        XCTAssertEqual(callerResult.registeredModeId, 1)
        XCTAssertEqual(callerResult.registeredModeEventNames, ["c"])
        XCTAssertEqual(callerResult.unregisteredModeId, 2)
        XCTAssertEqual(callerResult.unregisteredModeEventNames, ["d"])
        XCTAssertEqual(callerResult.registeredViewId, 3)
        XCTAssertEqual(callerResult.registeredViewEventNames, ["e"])
        XCTAssertEqual(callerResult.unregisteredViewId, 4)
        XCTAssertEqual(callerResult.unregisteredViewEventNames, ["f"])
    }

    // MARK: - one record per command, category/level per outcome

    func testSuccessEmitsExactlyOneBridgeDebugRecord() {
        let delegate = BlockCommand { result in result.success(result: "ok") }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))

        sut.execute(result: FakeFrameworksResult())

        let record = ScanditLogger.shared.getRecentLogs()[0]
        XCTAssertEqual(record.category, .bridge)
        XCTAssertEqual(record.level, .debug)
        XCTAssertNotNil(record.durationMs)
        XCTAssertGreaterThanOrEqual(record.durationMs ?? -1, 0)
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().count, 1)
    }

    func testSuccessAndKeepCallbackEmitsExactlyOneListenerDebugRecord() {
        let delegate = BlockCommand { result in result.successAndKeepCallback(result: "ok") }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))

        sut.execute(result: FakeFrameworksResult())

        let record = ScanditLogger.shared.getRecentLogs()[0]
        XCTAssertEqual(record.category, .listener)
        XCTAssertEqual(record.level, .debug)
    }

    func testRejectEmitsExactlyOneBridgeErrorRecordCarryingTheErrorCodeAndMessage() {
        let delegate = BlockCommand { result in result.reject(code: "MyError", message: "bad thing", details: nil) }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))

        sut.execute(result: FakeFrameworksResult())

        let record = ScanditLogger.shared.getRecentLogs()[0]
        XCTAssertEqual(record.category, .bridge)
        XCTAssertEqual(record.level, .error)
        XCTAssertEqual(record.error?.name, "MyError")
        XCTAssertEqual(record.error?.message, "bad thing")
    }

    func testRejectWithANilMessageRecordsAnEmptyStringNotNil() {
        let delegate = BlockCommand { result in result.reject(code: "MyError", message: nil, details: nil) }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))

        sut.execute(result: FakeFrameworksResult())

        XCTAssertEqual(ScanditLogger.shared.getRecentLogs()[0].error?.message, "")
    }

    func testADelegateThatNeitherCallsBackNorThrowsEmitsZeroRecords() {
        // LoggingCommand only emits from the instrumented result's
        // success/successAndKeepCallback/reject overrides. A delegate that
        // returns normally without ever invoking the result produces no log
        // record at all.
        let delegate = BlockCommand { _ in }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m"))

        sut.execute(result: FakeFrameworksResult())

        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    // NOTE: Android's "a delegate that throws propagates the identical
    // throwable and emits one error record" and "a delegate that reports
    // success and then throws emits two records" have no Swift analog:
    // `BaseCommand.execute(result:)` (Command/BaseCommand.swift) is
    // non-throwing, so a Swift delegate cannot express "report success, then
    // throw" — there is no catch block in `LoggingCommand.execute` to pin.

    // MARK: - wrap

    func testWrapDecoratesAPlainCommandIntoALoggingCommand() {
        let plain = BlockCommand { _ in }
        let wrapped = LoggingCommand.wrap(plain, source: "src", method: FakeMethodCall(method: "m"))
        XCTAssertTrue(wrapped is LoggingCommand)
    }

    func testWrapOnAnExistingLoggingCommandIsIdempotentAndReturnsTheSameInstance() {
        let plain = BlockCommand { _ in }
        let already = LoggingCommand(delegate: plain, source: "src", method: FakeMethodCall(method: "m"))
        let wrapped = LoggingCommand.wrap(already, source: "src", method: FakeMethodCall(method: "m"))
        XCTAssertEqual(ObjectIdentifier(wrapped as AnyObject), ObjectIdentifier(already))
    }

    // MARK: - extractFields, observed through the emitted record's fields

    func testNumericDispatcherIdsAreHoistedWhileDispatcherKeysAreDroppedAndTheRestIsNestedUnderArgs() {
        let args: [String: Any] = [
            "modeId": 3,
            "viewId": 4,
            "parentId": 5,
            "moduleName": "Core",
            "methodName": "foo",
            "isEventRegistration": true,
            "extra": "value",
        ]
        let delegate = BlockCommand { result in result.success(result: nil) }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m", args: args))

        sut.execute(result: FakeFrameworksResult())

        let fields = ScanditLogger.shared.getRecentLogs()[0].fields
        XCTAssertEqual(fields?.count, 4)
        XCTAssertEqual(fields?["modeId"] as? Int, 3)
        XCTAssertEqual(fields?["viewId"] as? Int, 4)
        XCTAssertEqual(fields?["parentId"] as? Int, 5)
        let inner = fields?["args"] as? [String: Any?]
        XCTAssertEqual(inner?.count, 1)
        XCTAssertEqual(inner?["extra"] as? String, "value")
    }

    func testFrameDataViewBytesLicenseKeysAndOversizedArgsAreNeverStoredInARecord() {
        let hugeString = String(repeating: "x", count: LoggingCommand.maxArgChars + 1)
        let args: [String: Any] = [
            "frameData": "base64-frame",
            "viewBytes": Data(count: 4),
            "licenseKey": "LK",
            "contextJson": #"{"licenseKey" : "LK","deviceName":"d"}"#,
            "settingsJson": hugeString,
            "image": Data(count: 16),
            "extra": "value",
        ]
        let delegate = BlockCommand { result in result.success(result: nil) }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m", args: args))

        sut.execute(result: FakeFrameworksResult())

        let inner = ScanditLogger.shared.getRecentLogs()[0].fields?["args"] as? [String: Any?]
        XCTAssertEqual(inner?["frameData"] as? String, "[redacted]")
        XCTAssertEqual(inner?["viewBytes"] as? String, "[redacted]")
        XCTAssertEqual(inner?["licenseKey"] as? String, "[redacted]")
        XCTAssertEqual(inner?["contextJson"] as? String, #"{"licenseKey":"[redacted]","deviceName":"d"}"#)
        XCTAssertEqual(inner?["settingsJson"] as? String, "[omitted: \(hugeString.count) chars]")
        XCTAssertEqual(inner?["image"] as? String, "[omitted: 16 bytes]")
        XCTAssertEqual(inner?["extra"] as? String, "value")
    }

    func testWhenOnlyDispatcherAndIdKeysArePresentThereIsNoArgsKey() {
        let args: [String: Any] = [
            "modeId": 1,
            "moduleName": "Core",
            "methodName": "foo",
            "isEventRegistration": false,
        ]
        let delegate = BlockCommand { result in result.success(result: nil) }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m", args: args))

        sut.execute(result: FakeFrameworksResult())

        let fields = ScanditLogger.shared.getRecentLogs()[0].fields
        XCTAssertEqual(fields?.count, 1)
        XCTAssertEqual(fields?["modeId"] as? Int, 1)
        XCTAssertNil(fields?["args"])
    }

    func testWhenArgumentsIsEmptyFieldsIsNil() {
        let delegate = BlockCommand { result in result.success(result: nil) }
        let sut = LoggingCommand(delegate: delegate, source: "src", method: FakeMethodCall(method: "m", args: [:]))

        sut.execute(result: FakeFrameworksResult())

        XCTAssertNil(ScanditLogger.shared.getRecentLogs()[0].fields)
    }

    // NOTE: Android's "when arguments throws fields is null and no exception
    // escapes" has no Swift analog: `FrameworksMethodCall.arguments()`
    // (Method/FrameworksMethodCall.swift:18) is non-throwing, so
    // `extractFields()` has nothing to catch.

    // MARK: - CoreModule.execute's ordinary (non-interception) dispatch

    func testExecuteWrapsAKnownMethodsCommandInLoggingCommandTaggedWithTheModulesTypeAsSource() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let fwModule = FakeFrameworkModule()
        fwModule.commandToReturn = BlockCommand { result in result.success(result: "ok") }
        let method = FakeMethodCall(method: "someKnownMethod")
        let result = FakeFrameworksResult()

        let handled = module.execute(method, result: result, module: fwModule)

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 1)
        XCTAssertTrue(result.successCalled)
        let record = ScanditLogger.shared.getRecentLogs()[0]
        XCTAssertEqual(record.source, "ios.FakeFrameworkModule")
        XCTAssertEqual(record.category, .bridge)
        XCTAssertEqual(record.level, .debug)
    }

    func testExecuteReturnsFalseWhenTheModuleCannotCreateACommandForTheMethod() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(method: "someUnknownMethod")
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        let handled = module.execute(method, result: result, module: fwModule)

        XCTAssertFalse(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 1)
        XCTAssertFalse(result.successCalled)
        XCTAssertFalse(result.rejectCalled)
        XCTAssertTrue(ScanditLogger.shared.getRecentLogs().isEmpty)
    }

    // MARK: - setLoggerConfig interception in CoreModule.execute

    func testSetLoggerConfigIsInterceptedBeforeTheGeneratedCommandFactoryRuns() {
        // Deliberately start from a state that differs from what the call
        // installs, so the assertions below prove the interception applied the
        // config rather than merely matching this class's setUp defaults.
        ScanditLogger.shared.setLevel(.off)
        ScanditLogger.shared.setCategories(.bridge)

        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(
            method: "setLoggerConfig",
            args: ["level": 5, "categories": LogCategory.all.rawValue, "bufferSize": 42]
        )
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        let handled = module.execute(method, result: result, module: fwModule)

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 0)
        XCTAssertEqual(ScanditLogger.shared.getLevel(), .trace)
        XCTAssertEqual(ScanditLogger.shared.getCategories(), .all)
        XCTAssertEqual(ScanditLogger.shared.getBufferSize(), 42)
        XCTAssertTrue(result.successCalled)
        XCTAssertNil(result.successResult)
    }

    func testSetLoggerConfigWithAnAbsentLevelDefaultsToOff() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(method: "setLoggerConfig", args: ["categories": LogCategory.all.rawValue])
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        _ = module.execute(method, result: result, module: fwModule)

        XCTAssertEqual(ScanditLogger.shared.getLevel(), .off)
    }

    func testSetLoggerConfigWithALevelOfTheWrongTypeDefaultsToOffJustLikeAnAbsentLevel() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(method: "setLoggerConfig", args: ["level": "not-a-number"])
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        _ = module.execute(method, result: result, module: fwModule)

        XCTAssertEqual(ScanditLogger.shared.getLevel(), .off)
    }

    func testSetLoggerConfigWithAbsentCategoriesAndBufferSizeLeavesThoseSettingsUntouched() {
        ScanditLogger.shared.setCategories(.bridge)
        ScanditLogger.shared.setBufferSize(77)
        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(method: "setLoggerConfig", args: ["level": 3])
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        _ = module.execute(method, result: result, module: fwModule)

        XCTAssertEqual(ScanditLogger.shared.getLevel(), .info)
        XCTAssertEqual(ScanditLogger.shared.getCategories(), .bridge)
        XCTAssertEqual(ScanditLogger.shared.getBufferSize(), 77)
    }

    // NOTE: Android's "setLoggerConfig reports a LoggerConfigError when
    // arguments throws" has no Swift analog: `handleSetLoggerConfig`
    // (CoreModule.swift:754-773) always calls `result.success(nil)` — there is
    // no error path, because `method.arguments()` cannot throw in Swift.

    // MARK: - writeLogs interception in CoreModule.execute

    func testWriteLogsIsInterceptedBeforeTheGeneratedCommandFactoryRunsAndResolvesWithTheWrittenPath() throws {
        // An absolute path keeps the spec off the test host's documents
        // directory: `LogExportFile.write` uses it as given, so nothing here
        // depends on where the app container happens to be.
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("export.jsonl")

        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(
            method: "writeLogs",
            args: ["path": destination.path, "header": "{\"recordCount\":1}", "body": "{\"message\":\"m1\"}"]
        )
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        let handled = module.execute(method, result: result, module: fwModule)

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 0)
        XCTAssertTrue(result.successCalled)
        XCTAssertFalse(result.rejectCalled)
        XCTAssertEqual(result.successResult as? String, destination.path)

        // The platform extras are CoreModule's own contribution to the header —
        // LogExportFile only merges whatever it is handed.
        let firstLine = try String(contentsOf: destination, encoding: .utf8).components(separatedBy: "\n")[0]
        let header = try JSONSerialization.jsonObject(with: Data(firstLine.utf8)) as? [String: Any]
        XCTAssertEqual(header?["platform"] as? String, "ios")
    }

    func testWriteLogsWithAMissingPathReportsWriteLogsError() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(method: "writeLogs", args: ["header": "{}", "body": "b"])
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        let handled = module.execute(method, result: result, module: fwModule)

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 0)
        XCTAssertTrue(result.rejectCalled)
        XCTAssertEqual(result.rejectCode, "WriteLogsError")
        XCTAssertEqual(result.rejectMessage, "writeLogs: missing path/header/body")
        XCTAssertFalse(result.successCalled)
    }

    func testWriteLogsWithAMissingHeaderReportsWriteLogsError() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(method: "writeLogs", args: ["path": "export.jsonl", "body": "b"])
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        let handled = module.execute(method, result: result, module: fwModule)

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 0)
        XCTAssertEqual(result.rejectCode, "WriteLogsError")
        XCTAssertEqual(result.rejectMessage, "writeLogs: missing path/header/body")
        XCTAssertFalse(result.successCalled)
    }

    func testWriteLogsWithAMissingBodyReportsWriteLogsError() {
        let module = CoreModule.create(emitter: RecordingEmitter())
        let method = FakeMethodCall(method: "writeLogs", args: ["path": "export.jsonl", "header": "{}"])
        let result = FakeFrameworksResult()
        let fwModule = FakeFrameworkModule()

        let handled = module.execute(method, result: result, module: fwModule)

        XCTAssertTrue(handled)
        XCTAssertEqual(fwModule.createCommandCallCount, 0)
        XCTAssertEqual(result.rejectCode, "WriteLogsError")
        XCTAssertEqual(result.rejectMessage, "writeLogs: missing path/header/body")
        XCTAssertFalse(result.successCalled)
    }

    // NOTE: Android's "writeLogs without an Android context reports
    // WriteLogsError" has no Swift analog: `handleWriteLogs`
    // (CoreModule.swift:805-837) resolves its base directory from
    // `FileManager`, which needs no injected context and cannot be absent.

    // MARK: - CoreModule construction registers its emitter with ScanditLogger

    func testCoreModuleConstructionRegistersItsEmitterWithScanditLoggerSoLogsAreShipped() {
        let emitter = RecordingEmitter(target: 50)

        _ = CoreModule.create(emitter: emitter)

        for i in 1...50 {
            ScanditLogger.shared.emit(level: .info, category: .bridge, source: "src", message: "msg-\(i)")
        }

        wait(for: [emitter.allShipped], timeout: 2)
        XCTAssertEqual(emitter.shippedCount, 50)
    }
}
