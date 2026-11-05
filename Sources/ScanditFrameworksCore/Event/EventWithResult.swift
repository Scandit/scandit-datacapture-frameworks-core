/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation

public let defaultTimeoutInterval: TimeInterval = 2.0

public class EventWithResult<T> {
    private let event: Event
    public var timeout: TimeInterval

    private var result: T?

    let condition = NSCondition()
    var isCallbackFinished = true

    private let isMainThread: () -> Bool
    private let onMainThreadEmit: () -> Void

    public convenience init(event: Event, timeout: TimeInterval = defaultTimeoutInterval) {
        self.init(
            event: event,
            timeout: timeout,
            isMainThread: { Thread.isMainThread },
            onMainThreadEmit: { assertionFailure("EventWithResult.emit must be called off the main thread") }
        )
    }

    init(
        event: Event,
        timeout: TimeInterval,
        isMainThread: @escaping () -> Bool,
        onMainThreadEmit: @escaping () -> Void
    ) {
        self.event = event
        self.timeout = timeout
        self.isMainThread = isMainThread
        self.onMainThreadEmit = onMainThreadEmit
    }

    private var isClosed = false

    @discardableResult
    public func emit(on emitter: Emitter, payload: [String: Any?], default: T? = nil) -> T? {
        // Waiting on main would freeze the UI for up to the full timeout.
        if isMainThread() {
            onMainThreadEmit()
            Log.info("\(event.name) was emitted on the main thread; returning the default")
            return `default`
        }

        let timeoutDate = Date(timeIntervalSinceNow: timeout)

        condition.lock()
        result = `default`
        if isClosed {
            let value = result
            condition.unlock()
            return value
        }
        isCallbackFinished = false
        condition.unlock()

        dispatchMain { [weak self] in
            guard let self else { return }
            emitter.emit(name: self.event.name, payload: payload)
        }

        condition.lock()
        while !isCallbackFinished {
            if !condition.wait(until: timeoutDate) {
                Log.info("Waited for \(event.name) to finish for \(timeout) seconds")
                isCallbackFinished = true
            }
        }
        let value = result
        condition.unlock()

        return value
    }

    public func unlock(value: T?) {
        condition.lock()
        result = value
        isCallbackFinished = true
        condition.signal()
        condition.unlock()
    }

    public func reset() {
        condition.lock()
        isCallbackFinished = true
        condition.signal()
        condition.unlock()
    }

    // Rejects emits and releases any waiting emit until open() is called; unlike reset(),
    // this also covers an emit that reaches its wait after the close.
    public func close() {
        condition.lock()
        isClosed = true
        isCallbackFinished = true
        condition.broadcast()
        condition.unlock()
    }

    public func open() {
        condition.lock()
        isClosed = false
        condition.unlock()
    }
}
