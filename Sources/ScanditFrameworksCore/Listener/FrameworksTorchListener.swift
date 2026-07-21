/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class FrameworksTorchListener: NSObject {
    private let eventEmitter: Emitter
    private let torchStateChangedEvent = Event(.torchStateChanged)

    public init(eventEmitter: Emitter) {
        self.eventEmitter = eventEmitter
    }
}

extension FrameworksTorchListener: TorchListener {
    public func didChangeTorch(to torchState: TorchState) {
        guard eventEmitter.hasListener(for: torchStateChangedEvent) else { return }
        torchStateChangedEvent.emit(on: eventEmitter, payload: ["state": torchState.jsonString])
    }
}
