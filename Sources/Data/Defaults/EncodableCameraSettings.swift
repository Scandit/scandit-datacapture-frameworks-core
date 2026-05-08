/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct EncodableCameraSettings: DefaultsEncodable {
    private let cameraSettings: CameraSettings

    init(cameraSettings: CameraSettings) {
        self.cameraSettings = cameraSettings
    }

    func toEncodable() -> [String: Any?] {
        [
            "preferredResolution": cameraSettings.preferredResolution.jsonString,
            "zoomFactor": cameraSettings.zoomFactor,
            "focusRange": cameraSettings.focusRange.jsonString,
            "focusGestureStrategy": cameraSettings.focusGestureStrategy.jsonString,
            "zoomGestureZoomFactor": cameraSettings.zoomGestureZoomFactor,
            "shouldPreferSmoothAutoFocus": cameraSettings.shouldPreferSmoothAutoFocus
        ]
    }
}
