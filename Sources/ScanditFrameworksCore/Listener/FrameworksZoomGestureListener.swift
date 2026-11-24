/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class FrameworksZoomGestureListener: NSObject {
    private let eventEmitter: Emitter
    private let viewId: Int
    private let zoomInGestureEvent = Event(.zoomInGesture)
    private let zoomOutGestureEvent = Event(.zoomOutGesture)

    public init(eventEmitter: Emitter, viewId: Int) {
        self.eventEmitter = eventEmitter
        self.viewId = viewId
    }
}

extension FrameworksZoomGestureListener: ZoomGestureListener {
    public func zoomGestureDidZoom(in zoomGesture: any ZoomGesture) {
        guard eventEmitter.hasViewSpecificListenersForEvent(viewId: self.viewId, for: zoomInGestureEvent) else {
            return
        }
        let payload = SchemaTypes.ZoomGestureListenerOnZoomInGesture(
            viewId: self.viewId,
            zoomGesture: zoomGesture.jsonString,
            event: zoomInGestureEvent.name
        )
        zoomInGestureEvent.emit(on: eventEmitter, payload: payload.toDictionary())
    }

    public func zoomGestureDidZoomOut(_ zoomGesture: any ZoomGesture) {
        guard eventEmitter.hasViewSpecificListenersForEvent(viewId: self.viewId, for: zoomOutGestureEvent) else {
            return
        }
        let payload = SchemaTypes.ZoomGestureListenerOnZoomOutGesture(
            viewId: self.viewId,
            zoomGesture: zoomGesture.jsonString,
            event: zoomOutGestureEvent.name
        )
        zoomOutGestureEvent.emit(on: eventEmitter, payload: payload.toDictionary())
    }
}
