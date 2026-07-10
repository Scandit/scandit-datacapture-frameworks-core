/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

open class FrameworksDataCaptureViewListener: NSObject {
    private let event = Event(.dataCaptureViewSizeChanged)
    private let eventEmitter: Emitter

    private var isEnabled = AtomicBool()

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

extension FrameworksDataCaptureViewListener: DataCaptureViewListener {
    public func dataCaptureView(_ view: DataCaptureView,
                                didChange size: CGSize,
                                orientation: UIInterfaceOrientation) {
        guard isEnabled.value, eventEmitter.hasListener(for: event) else { return }
        let payload = [
            "size": [
                "width": size.width,
                "height": size.height
            ],
            "orientation": orientation.jsonString
        ] as [String: Any]
        event.emit(on: eventEmitter, payload: payload)
    }
}
