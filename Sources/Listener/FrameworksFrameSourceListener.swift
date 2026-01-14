/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

open class FrameworksFrameSourceListener: NSObject {
    private let eventEmitter: Emitter
    private let frameSourceStateChangedEvent = Event(.frameSourceStateChanged)
    private let torchStateChangedEvent = Event(.torchStateChanged)

    private var isEnabled = AtomicValue<Bool>()

    public init(eventEmitter: Emitter) {
        self.eventEmitter = eventEmitter
    }

    public func enable() {
        isEnabled.value = true
    }

    public func disable() {
        isEnabled.value = false
    }
}

extension FrameworksFrameSourceListener: FrameSourceListener {
    public func frameSource(_ source: FrameSource, didChange newState: FrameSourceState) {
        var payload = ["state": newState.jsonString]
        
        if let camera = source as? Camera {
            payload["cameraPosition"] = camera.position.jsonString
        }
        
        guard isEnabled.value, eventEmitter.hasListener(for: frameSourceStateChangedEvent) else { return }
        frameSourceStateChangedEvent.emit(on: eventEmitter, payload: payload)
    }

    public func frameSource(_ source: FrameSource, didOutputFrame frame: FrameData) {}
}

extension FrameworksFrameSourceListener: TorchListener {
    public func didChangeTorch(to torchState: TorchState) {
        guard isEnabled.value, eventEmitter.hasListener(for: torchStateChangedEvent) else { return }
        torchStateChangedEvent.emit(on: eventEmitter, payload: ["state": torchState.jsonString])
    }
}
