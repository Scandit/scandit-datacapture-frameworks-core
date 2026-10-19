/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

public struct Event {
    let name: String

    public init(name: String) {
        self.name = name
    }

    public func emit(on emitter: Emitter, payload: [String: Any]) {
        var payload = payload
        payload["event"] = name
        emitter.emit(name: name, payload: payload)
    }
}

extension Event {
    init(_ event: ScanditFrameworksCoreEvent) {
        self.init(name: event.rawValue)
    }
}
