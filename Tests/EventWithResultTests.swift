/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

private class NonAnsweringEmitter: Emitter {
    // The framework-side answer never arrives, like a listener torn down mid-event;
    // the hook only reports that the emit reached the emitter.
    var onEmit: (() -> Void)?

    func emit(name: String, payload: [String: Any?]) {
        onEmit?()
    }

    func hasListener(for event: String) -> Bool {
        true
    }

    func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool {
        true
    }

    func hasModeSpecificListenersForEvent(_ modeId: Int, for event: String) -> Bool {
        true
    }
}

final class EventWithResultTests: XCTestCase {
    private var event: EventWithResult<Bool>!
    private let emitter = NonAnsweringEmitter()

    override func setUp() {
        super.setUp()
        event = EventWithResult<Bool>(event: Event(name: "test"), timeout: 5)
    }

    func testUnlockReleasesWaitingEmitWithValue() {
        let emitDispatched = expectation(description: "emit dispatched")
        emitter.onEmit = { emitDispatched.fulfill() }
        let emitReturned = expectation(description: "emit returned")
        var result: Bool?
        DispatchQueue.global().async { [event, emitter] in
            result = event!.emit(on: emitter, payload: [:], default: false)
            emitReturned.fulfill()
        }
        wait(for: [emitDispatched], timeout: 2)
        event.unlock(value: true)
        wait(for: [emitReturned], timeout: 2)
        XCTAssertEqual(result, true)
    }

    func testEmitAfterCloseReturnsDefaultImmediately() {
        event.close()

        let start = Date()
        let result = emitOffMain(default: true)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(result, true)
        XCTAssertLessThan(elapsed, 1, "closed event must not block until the timeout")
    }

    func testCloseUnblocksWaitingEmit() {
        let emitDispatched = expectation(description: "emit dispatched")
        emitter.onEmit = { emitDispatched.fulfill() }
        let emitReturned = expectation(description: "emit returned")
        var elapsed: TimeInterval = 0
        DispatchQueue.global().async { [event, emitter] in
            let start = Date()
            _ = event!.emit(on: emitter, payload: [:], default: false)
            elapsed = Date().timeIntervalSince(start)
            emitReturned.fulfill()
        }
        wait(for: [emitDispatched], timeout: 2)
        event.close()

        wait(for: [emitReturned], timeout: 2)
        XCTAssertLessThan(elapsed, 2, "close must release the waiting emit before its timeout")
    }

    func testOpenWhenAlreadyOpenIsIdempotent() {
        event.open()

        let emitDispatched = expectation(description: "emit dispatched")
        emitter.onEmit = { emitDispatched.fulfill() }
        let emitReturned = expectation(description: "emit returned")
        var result: Bool?
        DispatchQueue.global().async { [event, emitter] in
            result = event!.emit(on: emitter, payload: [:], default: false)
            emitReturned.fulfill()
        }
        wait(for: [emitDispatched], timeout: 2)
        event.unlock(value: true)
        wait(for: [emitReturned], timeout: 2)
        XCTAssertEqual(result, true)
    }

    func testOpenAfterCloseRestoresNormalOperation() {
        event.close()
        event.open()

        let emitDispatched = expectation(description: "emit dispatched")
        emitter.onEmit = { emitDispatched.fulfill() }
        let emitReturned = expectation(description: "emit returned")
        var result: Bool?
        DispatchQueue.global().async { [event, emitter] in
            result = event!.emit(on: emitter, payload: [:], default: false)
            emitReturned.fulfill()
        }
        wait(for: [emitDispatched], timeout: 2)
        event.unlock(value: true)
        wait(for: [emitReturned], timeout: 2)
        XCTAssertEqual(result, true)
    }

    func testEmitOnMainThreadReturnsDefaultWithoutEmitting() {
        var emitCount = 0
        emitter.onEmit = { emitCount += 1 }
        var handlerCount = 0
        let event = EventWithResult<Bool>(
            event: Event(name: "test"),
            timeout: 5,
            isMainThread: { true },
            onMainThreadEmit: { handlerCount += 1 }
        )

        let start = Date()
        let result = event.emit(on: emitter, payload: [:], default: true)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(result, true)
        XCTAssertLessThan(elapsed, 0.5)
        XCTAssertEqual(emitCount, 0)
        XCTAssertEqual(handlerCount, 1)
    }

    func testMainThreadEmitDoesNotDisturbSubsequentOffMainEmit() {
        var onMain = true
        let event = EventWithResult<Bool>(
            event: Event(name: "test"),
            timeout: 5,
            isMainThread: { onMain },
            onMainThreadEmit: {}
        )
        XCTAssertEqual(event.emit(on: emitter, payload: [:], default: false), false)

        onMain = false
        let emitDispatched = expectation(description: "emit dispatched")
        emitter.onEmit = { emitDispatched.fulfill() }
        let emitReturned = expectation(description: "emit returned")
        var result: Bool?
        DispatchQueue.global().async { [emitter] in
            result = event.emit(on: emitter, payload: [:], default: false)
            emitReturned.fulfill()
        }
        wait(for: [emitDispatched], timeout: 2)
        event.unlock(value: true)
        wait(for: [emitReturned], timeout: 2)
        XCTAssertEqual(result, true)
    }

    func testLateUnlockAfterTimeoutDoesNotReachNextEmit() {
        event.timeout = 0.05

        let first = emitOffMain(default: false)
        event.unlock(value: true)
        let second = emitOffMain(default: false)

        XCTAssertEqual(first, false)
        XCTAssertEqual(second, false)
    }

    private func emitOffMain(default value: Bool) -> Bool? {
        let emitReturned = expectation(description: "emit returned")
        var result: Bool?
        DispatchQueue.global().async { [event, emitter] in
            result = event!.emit(on: emitter, payload: [:], default: value)
            emitReturned.fulfill()
        }
        wait(for: [emitReturned], timeout: 2)
        return result
    }
}
