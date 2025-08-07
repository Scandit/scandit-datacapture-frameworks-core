/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

public protocol Emitter {
    func emit(name: String, payload: [String: Any?])
    func hasListener(for event: String) -> Bool
}

public extension Emitter {
    func hasListener(for event: Event) -> Bool {
        hasListener(for: event.name)
    }
}
