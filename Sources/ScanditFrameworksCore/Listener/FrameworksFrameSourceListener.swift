/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

open class FrameworksFrameSourceListener: NSObject {
    private let eventEmitter: Emitter
    private let frameSourceStateChangedEvent = Event(.frameSourceStateChanged)

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
        guard isEnabled.value, eventEmitter.hasListener(for: frameSourceStateChangedEvent) else { return }
        // cameraPosition is omitted entirely for a non-Camera frame source (not sent as null) --
        // jsmobile's CameraController must treat it as optional (SDC-32670).
        let payload = SchemaTypes.FrameSourceListenerOnStateChanged(
            state: newState.jsonString,
            cameraPosition: (source as? Camera)?.position.jsonString,
            event: frameSourceStateChangedEvent.name
        )
        frameSourceStateChangedEvent.emit(on: eventEmitter, payload: payload.toDictionary())
    }

    public func frameSource(_ source: FrameSource, didOutputFrame frame: FrameData) {}
}
