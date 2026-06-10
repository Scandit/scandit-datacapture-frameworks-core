/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

public enum ScanditFrameworksCoreEvent: String, CaseIterable {
    case contextStatusChanged = "DataCaptureContextListener.onStatusChanged"
    case contextObservingStarted = "DataCaptureContextListener.onObservationStarted"
    case dataCaptureViewSizeChanged = "DataCaptureViewListener.onSizeChanged"
    case frameSourceStateChanged = "FrameSourceListener.onStateChanged"
    case torchStateChanged = "TorchListener.onTorchStateChanged"
}
