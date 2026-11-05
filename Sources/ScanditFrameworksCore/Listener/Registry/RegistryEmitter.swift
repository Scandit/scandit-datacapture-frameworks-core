/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

public final class RegistryEmitter: Emitter {
    private let registry: ListenerRegistry
    private let platformEmitter: Emitter

    public init(platformEmitter: Emitter, registry: ListenerRegistry = .shared) {
        self.registry = registry
        self.platformEmitter = platformEmitter
    }

    public func emit(name: String, payload: [String: Any?]) {
        let target = ListenerTarget.of(viewId: payload["viewId"] as? Int, modeId: payload["modeId"] as? Int)
        if let coreEmitter = CoreEventEmitter.emitter, routesToCore(name, target) {
            coreEmitter.emit(name: name, payload: payload)
        } else {
            platformEmitter.emit(name: name, payload: payload)
        }
    }

    // A payload without viewId/modeId cannot name its target;
    // JS dispatches it to the event's listener.
    private func routesToCore(_ name: String, _ target: ListenerTarget) -> Bool {
        registry.hasListeners(eventName: name, target: target)
            || (target == .global && registry.hasListeners(eventName: name))
    }

    public func hasListener(for event: String) -> Bool {
        registry.hasListeners(eventName: event) || platformEmitter.hasListener(for: event)
    }

    public func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool {
        registry.hasListeners(eventName: event, target: .view(viewId))
            || platformEmitter.hasViewSpecificListenersForEvent(viewId, for: event)
    }

    public func hasModeSpecificListenersForEvent(_ modeId: Int, for event: String) -> Bool {
        registry.hasListeners(eventName: event, target: .mode(modeId))
            || platformEmitter.hasModeSpecificListenersForEvent(modeId, for: event)
    }
}
