/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

open class FrameworksDataCaptureContextListener: NSObject {

    private let eventEmitter: Emitter
    private let observationStartedEvent = Event(.contextObservingStarted)
    private let didChangeStatusEvent = Event(.contextStatusChanged)
    private let frameSourceChangedEvent = Event(.contextFrameSourceChanged)

    private var isEnabled = AtomicValue<Bool>()

    /// Invoked whenever the context's frame source changes — including changes initiated purely
    /// on the native side (e.g. the CameraSwitchControl swapping cameras). Not gated on
    /// `isEnabled`: this drives internal frameworks state-keeping, not a JS-facing event.
    public var onFrameSourceChanged: ((FrameSource?) -> Void)?

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

extension FrameworksDataCaptureContextListener: DataCaptureContextListener {
    public func context(_ context: DataCaptureContext, didChange frameSource: FrameSource?) {
        // Ungated and first: DefaultFrameSourceHandler must re-target regardless of subscribers.
        onFrameSourceChanged?(frameSource)

        guard isEnabled.value, eventEmitter.hasListener(for: frameSourceChangedEvent) else { return }
        // cameraPosition is omitted for a nil or non-Camera frame source; `unspecified` is a
        // valid position, so absence is the only way to say "no camera".
        let payload = SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged(
            cameraPosition: (frameSource as? Camera)?.position.jsonString,
            event: frameSourceChangedEvent.name
        )
        frameSourceChangedEvent.emit(on: eventEmitter, payload: payload.toDictionary())
    }

    public func context(_ context: DataCaptureContext, didAdd mode: DataCaptureMode) {}

    public func context(_ context: DataCaptureContext, didRemove mode: DataCaptureMode) {}

    public func context(_ context: DataCaptureContext, didChange contextStatus: ContextStatus) {
        guard isEnabled.value, eventEmitter.hasListener(for: didChangeStatusEvent) else { return }
        let payload = SchemaTypes.DataCaptureContextListenerOnStatusChanged(
            status: contextStatus.jsonString,
            event: ScanditFrameworksCoreEvent.contextStatusChanged.rawValue
        )
        didChangeStatusEvent.emit(on: eventEmitter, payload: payload.toDictionary())
    }

    public func didStartObserving(_ context: DataCaptureContext) {
        guard isEnabled.value, eventEmitter.hasListener(for: observationStartedEvent) else { return }
        // licenseInfo is wire-present but read only by Flutter today; jsmobile's
        // DataCaptureContextController never reads it (no new consumer added here).
        let payload = SchemaTypes.DataCaptureContextListenerOnObservationStarted(
            licenseInfo: context.licenseInfo?.jsonString,
            event: ScanditFrameworksCoreEvent.contextObservingStarted.rawValue
        )
        observationStartedEvent.emit(on: eventEmitter, payload: payload.toDictionary())
    }
}
