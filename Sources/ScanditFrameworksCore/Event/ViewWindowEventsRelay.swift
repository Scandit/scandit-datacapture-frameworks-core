/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Relays per-view window attach/detach signals to the framework layer's event
/// emitter (SDC-32484 single-owner camera model): the JS/framework layer claims
/// camera ownership when a scanner view's native view enters a window and
/// releases it when it leaves. The hosting framework registers its emitter at
/// module setup; view containers call `notifyWindowChanged` from their
/// window-lifecycle hooks. No-op until an emitter is registered.
@objc(SDCViewWindowEventsRelay)
@objcMembers
public class ViewWindowEventsRelay: NSObject {
    public static let windowAttachedEvent = "NativeView.onWindowAttached"
    public static let windowDetachedEvent = "NativeView.onWindowDetached"

    private static var emitter: Emitter?

    /// Registered once by the hosting framework's core module setup.
    public static func setEmitter(_ newEmitter: Emitter?) {
        emitter = newEmitter
    }

    /// Emit a window attach/detach event for the view with the given id
    /// (the React tag on React Native). Ignored for invalid ids (<= 0).
    public static func notifyWindowChanged(viewId: Int, attached: Bool) {
        guard viewId > 0, let emitter = emitter else { return }
        emitter.emit(
            name: attached ? windowAttachedEvent : windowDetachedEvent,
            payload: ["viewId": viewId]
        )
    }
}
