/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public struct CameraSettingsPropertiesDefaults: DefaultsEncodable {
    private let cameraSettings: CameraSettings

    public init(cameraSettings: CameraSettings) {
        self.cameraSettings = cameraSettings
    }

    public func toEncodable() -> [String: Any?] {
        [
            "minFrameRate": cameraSettings.value(forProperty: "minFrameRate"),
            "colorCorrection": cameraSettings.value(forProperty: "colorCorrection"),
            "edgeEnhancementMode": cameraSettings.value(forProperty: "edgeEnhancementMode"),
            "toneMappingCurve": cameraSettings.value(forProperty: "toneMappingCurve"),
            "noiseReductionMode": cameraSettings.value(forProperty: "noiseReductionMode"),
            "macroAutofocusMode": cameraSettings.value(forProperty: "macroAutofocusMode"),
            "preferredAspectRatio": cameraSettings.value(forProperty: "preferredAspectRatio"),
            "exposureTargetBias": cameraSettings.value(forProperty: "exposureTargetBias"),
            "triggerAf": cameraSettings.value(forProperty: "triggerAf"),
            "api": cameraSettings.value(forProperty: "api"),
            "disableManualLensPositionSupportCheck": cameraSettings.value(
                forProperty: "disableManualLensPositionSupportCheck"
            ),
            "xcoverInitialLensPosition": cameraSettings.value(forProperty: "xcoverInitialLensPosition"),
            "regionStrategy": cameraSettings.value(forProperty: "regionStrategy"),
            "scanPhaseNoSreTimeout": cameraSettings.value(forProperty: "scanPhaseNoSreTimeout"),
            "closestResolutionTo12MPForFourToThreeAspectRatio": cameraSettings.value(
                forProperty: "closestResolutionTo12MPForFourToThreeAspectRatio"
            ),
            "cameraDeviceType": cameraSettings.value(forProperty: "cameraDeviceType"),
            "repeatedTriggerInterval": cameraSettings.value(forProperty: "repeatedTriggerInterval"),
            "range": cameraSettings.value(forProperty: "range"),
            "manualLensPosition": cameraSettings.value(forProperty: "manualLensPosition"),
            "focusStrategy": cameraSettings.value(forProperty: "focusStrategy"),
            "overwriteWithHighestResolution": cameraSettings.value(forProperty: "overwriteWithHighestResolution"),
            "disableRetriggerAndContinuous": cameraSettings.value(forProperty: "disableRetriggerAndContinuous"),
            "forceAggressiveAutoFocus": cameraSettings.value(forProperty: "forceAggressiveAutoFocus"),
            "searchPhaseRetriggerInterval": cameraSettings.value(forProperty: "searchPhaseRetriggerInterval"),
            "numOfScanPhaseTriggerCycles": cameraSettings.value(forProperty: "numOfScanPhaseTriggerCycles"),
            "maxExposureDuration": cameraSettings.value(forProperty: "maxExposureDuration"),
            "initialSingleShotFocusDuration": cameraSettings.value(forProperty: "initialSingleShotFocusDuration"),
            "sharpnessStrength": cameraSettings.value(forProperty: "sharpnessStrength"),
            "exposureDuration": cameraSettings.value(forProperty: "exposureDuration"),
            "sensorSensitivity": cameraSettings.value(forProperty: "sensorSensitivity"),
            "prefer_binned_format": cameraSettings.value(forProperty: "prefer_binned_format"),
            "videoHDRMode": cameraSettings.value(forProperty: "videoHDRMode"),
            "scenario_a_smart_af": cameraSettings.value(forProperty: "scenario_a_smart_af"),
        ].filter { $0.value != nil }
    }
}
