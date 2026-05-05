/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class FrameworksZoomListener: NSObject {
    private let eventEmitter: Emitter
    private let zoomLevelChangedEvent = Event(.zoomLevelChanged)

    public init(eventEmitter: Emitter) {
        self.eventEmitter = eventEmitter
    }
}

extension FrameworksZoomListener: ZoomListener {
    public func didChangeZoomFactor(_ zoomFactor: CGFloat, oldZoomFactor: CGFloat) {
        guard eventEmitter.hasListener(for: zoomLevelChangedEvent) else { return }
        zoomLevelChangedEvent.emit(
            on: eventEmitter,
            payload: [
                "oldZoomLevel": oldZoomFactor,
                "newZoomLevel": zoomFactor,
            ]
        )
    }
}
