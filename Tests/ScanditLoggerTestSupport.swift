/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation
import XCTest

@testable import ScanditFrameworksCore

/// Shared fixture helpers for the logging specs.
///
/// `ScanditLogger.shared` is a process-wide singleton and every XCTest class in
/// this module runs in the same process, so its configuration leaks between
/// tests and between classes unless each test restores it. This lives here
/// rather than being copy-pasted into every spec file so that adding a new
/// piece of logger state means editing ONE reset, not several that silently
/// drift apart.
enum ScanditLoggerTestSupport {
    static let defaultBufferSize = 1000

    /// Returns the logger's configuration and buffer to their as-constructed
    /// state.
    ///
    /// `registerEmitter(nil)` runs first so that nothing can be shipped while
    /// the rest of the state is being reset. Note what it does **not** do: it
    /// clears `pendingBatch` and `flushScheduled`, but it does **not** cancel a
    /// flush already scheduled on `flushQueue` (`ScanditLogger.swift:246-270`
    /// uses a bare `asyncAfter`, not a cancellable `DispatchWorkItem`). A class
    /// that attaches an emitter must therefore also call
    /// `drainScheduledFlush(_:)` — see the note there.
    ///
    /// `setBufferSize` is a no-op when the size already equals the current one
    /// (so it will NOT clear the buffer on its own) — the explicit `clear()`
    /// below is required.
    ///
    /// **Subscribers are the caller's responsibility.** `ScanditLogger` exposes
    /// no way to remove them in bulk, so this helper cannot reset them; a
    /// subscription that is never unsubscribed keeps firing for every later test
    /// in the module. Specs that subscribe must invoke the closure `subscribe`
    /// returned them — `ScanditLoggerTests` does this with a `track()` list
    /// drained in `tearDown`.
    static func resetLogger() {
        ScanditLogger.shared.registerEmitter(nil)
        ScanditLogger.shared.setLevel(.off)
        ScanditLogger.shared.setCategories(.defaults)
        ScanditLogger.shared.setBufferSize(defaultBufferSize)
        ScanditLogger.shared.clear()
    }

    /// Waits out the batch flush interval so no work item scheduled by the
    /// finished test survives into the next one. Call it in `tearDown`, **after**
    /// `resetLogger()`, from any class that attaches an emitter.
    ///
    /// Detaching the emitter is not enough: the `flushQueue.asyncAfter` work item
    /// stays queued and fires up to `batchFlushIntervalMs` later. By then the next
    /// test may have attached its own emitter and queued records, and
    /// `flushPending` will ship that partial batch — precisely the state the
    /// boundary specs assert cannot happen, so a stale timer can red a correct
    /// implementation. Draining after detaching means the item fires while
    /// `emitter` is nil and is a no-op.
    static func drainScheduledFlush(_ testCase: XCTestCase) {
        let elapsed = testCase.expectation(description: "batch flush interval elapsed")
        elapsed.isInverted = true
        testCase.wait(for: [elapsed], timeout: flushDrainSeconds)
    }

    /// Comfortably longer than `ScanditLogger`'s private 100 ms flush interval.
    private static let flushDrainSeconds: TimeInterval = 0.15
}

// MARK: - Shared fakes

/// Minimal `FrameworksMethodCall` double. `argument(key:)` / `hasArgument`
/// are derived from `args` so callers only need to supply the dictionary.
final class FakeMethodCall: FrameworksMethodCall {
    let method: String
    private let args: [String: Any]

    init(method: String, args: [String: Any] = [:]) {
        self.method = method
        self.args = args
    }

    func arguments() -> [String: Any] { args }

    func argument<T>(key: String) -> T? { args[key] as? T }

    func hasArgument(key: String) -> Bool { args[key] != nil }
}

/// `FrameworksResult` double. Records every terminal call made on it, plus the
/// exact payload, so tests can assert forwarding without a mocking framework.
final class FakeFrameworksResult: FrameworksResult {
    private(set) var successCalled = false
    private(set) var successResult: Any?
    private(set) var keepCallbackCalled = false
    private(set) var keepCallbackResult: Any?
    private(set) var rejectCalled = false
    private(set) var rejectCode: String?
    private(set) var rejectMessage: String?
    private(set) var rejectDetails: Any?

    func success(result: Any?) {
        successCalled = true
        successResult = result
    }

    func successAndKeepCallback(result: Any?) {
        keepCallbackCalled = true
        keepCallbackResult = result
    }

    func reject(code: String, message: String?, details: Any?) {
        rejectCalled = true
        rejectCode = code
        rejectMessage = message
        rejectDetails = details
    }

    func reject(error: Error) {
        rejectCalled = true
        rejectCode = (error as NSError).domain
        rejectMessage = error.localizedDescription
    }

    private(set) var registeredEventNames: [String]?
    private(set) var unregisteredEventNames: [String]?
    private(set) var registeredModeId: Int?
    private(set) var registeredModeEventNames: [String]?
    private(set) var unregisteredModeId: Int?
    private(set) var unregisteredModeEventNames: [String]?
    private(set) var registeredViewId: Int?
    private(set) var registeredViewEventNames: [String]?
    private(set) var unregisteredViewId: Int?
    private(set) var unregisteredViewEventNames: [String]?

    func registerCallbackForEvents(_ eventNames: [String]) { registeredEventNames = eventNames }
    func unregisterCallbackForEvents(_ eventNames: [String]) { unregisteredEventNames = eventNames }
    func registerModeSpecificCallback(_ modeId: Int, eventNames: [String]) {
        registeredModeId = modeId
        registeredModeEventNames = eventNames
    }
    func unregisterModeSpecificCallback(_ modeId: Int, eventNames: [String]) {
        unregisteredModeId = modeId
        unregisteredModeEventNames = eventNames
    }
    func registerViewSpecificCallback(_ viewId: Int, eventNames: [String]) {
        registeredViewId = viewId
        registeredViewEventNames = eventNames
    }
    func unregisterViewSpecificCallback(_ viewId: Int, eventNames: [String]) {
        unregisteredViewId = viewId
        unregisteredViewEventNames = eventNames
    }
}

/// `FrameworkModule` double. Records whether `createCommand` was invoked, so
/// interception tests can assert the generated command factory never ran.
/// `commandToReturn` lets callers supply the command the fake hands back
/// (defaults to `nil`, matching every existing call site's expectations).
final class FakeFrameworkModule: FrameworkModule {
    private(set) var createCommandCallCount = 0
    var commandToReturn: BaseCommand?

    func didStart() {}
    func didStop() {}

    func createCommand(_ method: FrameworksMethodCall) -> BaseCommand? {
        createCommandCallCount += 1
        return commandToReturn
    }
}

/// `BaseCommand` double that runs an arbitrary closure against the result it
/// is handed — the substitute for Android's anonymous `object : BaseCommand`
/// delegates in `LoggingCommandTest.kt`.
final class BlockCommand: BaseCommand {
    private let block: (FrameworksResult) -> Void

    init(_ block: @escaping (FrameworksResult) -> Void) {
        self.block = block
    }

    func execute(result: FrameworksResult) {
        block(result)
    }
}

/// Recording `Emitter` double for the batching specs. Thread-safe: `emit` is
/// called from both the emitting thread and the flush queue.
final class RecordingEmitter: Emitter {
    private let lock = NSLock()
    private var storedBatches: [[[String: Any?]]] = []
    private var storedShipped = 0

    /// Fulfilled once `shippedCount` reaches `target` (set at init). A target
    /// of 0 means "don't bother" — callers that don't need to await a count
    /// pass the default and never call `wait(for:)` on it.
    let allShipped: XCTestExpectation
    private let target: Int

    init(target: Int = 0) {
        self.target = target
        allShipped = XCTestExpectation(description: "emitter shipped \(target) records")
        if target <= 0 { allShipped.fulfill() }
    }

    func emit(name: String, payload: [String: Any?]) {
        lock.lock()
        defer { lock.unlock() }
        guard let records = payload["records"] as? [[String: Any?]] else { return }
        storedBatches.append(records)
        storedShipped += records.count
        if target > 0, storedShipped >= target {
            allShipped.fulfill()
        }
    }

    func hasListener(for event: String) -> Bool { false }
    func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool { false }
    func hasModeSpecificListenersForEvent(_ modeId: Int, for event: String) -> Bool { false }

    var batches: [[[String: Any?]]] {
        lock.lock()
        defer { lock.unlock() }
        return storedBatches
    }

    var shippedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedShipped
    }

    var records: [[String: Any?]] { batches.flatMap { $0 } }
}
