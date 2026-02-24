/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */
 
 import Foundation
 import ScanditCaptureCore
 
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
            "zoomGestureZoomFactor": cameraSettings.zoomGestureZoomFactor,
            "shouldPreferSmoothAutoFocus": cameraSettings.shouldPreferSmoothAutoFocus,
            "properties": CameraSettingsPropertiesDefaults(cameraSettings: cameraSettings).toEncodable()
         ]
     }
 }
