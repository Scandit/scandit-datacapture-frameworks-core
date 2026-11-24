/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

open class FrameworksDataCaptureViewListener: NSObject {
    private let event = Event(.dataCaptureViewSizeChanged)
    private let eventEmitter: Emitter
    private let viewId: Int

    private var isEnabled = AtomicValue<Bool>()

    public init(eventEmitter: Emitter, viewId: Int) {
        self.viewId = viewId
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
    public func dataCaptureView(
        _ view: DataCaptureView,
        didChange size: CGSize,
        orientation: UIInterfaceOrientation
    ) {
        guard isEnabled.value, eventEmitter.hasListener(for: event) else { return }
        let payload = SchemaTypes.DataCaptureViewListenerOnSizeChanged(
            viewId: self.viewId,
            size: SchemaTypes.DataCaptureViewListenerOnSizeChangedSize(
                width: size.width,
                height: size.height
            ),
            orientation: orientation.jsonString,
            event: ScanditFrameworksCoreEvent.dataCaptureViewSizeChanged.rawValue
        )
        event.emit(on: eventEmitter, payload: payload.toDictionary())
    }
}
