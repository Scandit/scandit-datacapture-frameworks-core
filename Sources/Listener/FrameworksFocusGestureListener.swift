/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class FrameworksFocusGestureListener: NSObject {
    private let eventEmitter: Emitter
    private let viewId: Int
    private let focusGestureEvent = Event(.focusGesture)

    public init(eventEmitter: Emitter, viewId: Int) {
        self.eventEmitter = eventEmitter
        self.viewId = viewId
    }
}

extension FrameworksFocusGestureListener: FocusGestureListener {
    public func focusGesture(_ focusGesture: any FocusGesture, didTriggerFocusAtPoint pointWithUnit: PointWithUnit) {
        guard eventEmitter.hasViewSpecificListenersForEvent(viewId: self.viewId, for: focusGestureEvent) else { return }
        focusGestureEvent.emit(
            on: eventEmitter,
            payload: [
                "viewId": self.viewId,
                "focusGesture": focusGesture.jsonString,
                "point": pointWithUnit.jsonString,
            ]
        )
    }
}
