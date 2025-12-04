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

    public init(event: Event, timeout: TimeInterval = defaultTimeoutInterval) {
        self.event = event
        self.timeout = timeout
    }

    @discardableResult
    public func emit(on emitter: Emitter, payload: [String: Any?], default: T? = nil) -> T? {
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        result = `default`
        isCallbackFinished = false

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
        condition.unlock()

        return result
    }

    public func unlock(value: T?) {
        result = value
        release()
    }

    public func reset() {
        release()
    }

    private func release() {
        isCallbackFinished = true
        condition.signal()
    }
}
