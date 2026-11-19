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
        onFrameSourceChanged?(frameSource)
    }

    public func context(_ context: DataCaptureContext, didAdd mode: DataCaptureMode) {}

    public func context(_ context: DataCaptureContext, didRemove mode: DataCaptureMode) {}

    public func context(_ context: DataCaptureContext, didChange contextStatus: ContextStatus) {
        guard isEnabled.value, eventEmitter.hasListener(for: didChangeStatusEvent) else { return }
        let payload = ["status": contextStatus.jsonString]
        didChangeStatusEvent.emit(on: eventEmitter, payload: payload)
    }

    public func didStartObserving(_ context: DataCaptureContext) {
        guard isEnabled.value, eventEmitter.hasListener(for: observationStartedEvent) else { return }
        let payload = ["licenseInfo": context.licenseInfo?.jsonString as Any]
        observationStartedEvent.emit(on: eventEmitter, payload: payload)
    }
}
