/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct CameraDefaults: DefaultsEncodable {
    private let cameraSettingsDefaults: EncodableCameraSettings
    private let defaultPosition: CameraPosition?
    private let availablePositions: [CameraPosition]?

    init(cameraSettingsDefaults: EncodableCameraSettings,
         defaultPosition: CameraPosition?,
         availablePositions: [CameraPosition]?) {
        self.cameraSettingsDefaults = cameraSettingsDefaults
        self.defaultPosition = defaultPosition
        self.availablePositions = availablePositions
    }

    func toEncodable() -> [String: Any?] {
        [
            "Settings": cameraSettingsDefaults.toEncodable(),
            "defaultPosition": defaultPosition?.jsonString,
            "availablePositions": availablePositions?.map { $0.jsonString }
        ]
    }
}
