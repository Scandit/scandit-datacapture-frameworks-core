/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

private protocol DeprecatedCameraSettingsAccessor {
    var zoomGestureZoomFactor: Double { get }
}

extension CameraSettingsDefaults: DeprecatedCameraSettingsAccessor {
    // Suppress deprecation warning — zoomGestureZoomFactor is still serialized for backward compatibility
    @available(*, deprecated)
    fileprivate var zoomGestureZoomFactor: Double {
        cameraSettings.zoomGestureZoomFactor
    }
}

public struct CameraSettingsDefaults: DefaultsEncodable {
    private let cameraSettings: CameraSettings

    public init(cameraSettings: CameraSettings) {
        self.cameraSettings = cameraSettings
    }

    public func toEncodable() -> [String: Any?] {
        [
            "preferredResolution": cameraSettings.preferredResolution.jsonString,
            "zoomFactor": cameraSettings.zoomFactor,
            "focusRange": cameraSettings.focusRange.jsonString,
            "focusGestureStrategy": cameraSettings.focusGestureStrategy.jsonString,
            "zoomGestureZoomFactor": (self as DeprecatedCameraSettingsAccessor).zoomGestureZoomFactor,
            "shouldPreferSmoothAutoFocus": cameraSettings.shouldPreferSmoothAutoFocus,
            "torchLevel": cameraSettings.torchLevel,
            "macroMode": cameraSettings.macroMode.jsonString,
            "adaptiveExposure": cameraSettings.adaptiveExposure,
            "properties": CameraSettingsPropertiesDefaults(cameraSettings: cameraSettings).toEncodable(),
            "zoomLevels": Array(cameraSettings.zoomLevels),
        ]
    }
}
