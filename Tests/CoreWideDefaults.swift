/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

@testable import ScanditFrameworksCore

/// Test-only *wide* defaults builders.
///
/// Production only ever emits the narrow, dynamic payload (`CoreDefaults.toDynamicEncodable()`),
/// so the wide `toEncodable()` graph - including the UIKit objects (`DataCaptureView`,
/// `AimerViewfinder`, `LaserlineViewfinder`, `RectangularViewfinder`) it has to construct - lives
/// here, in the test target only. It is the oracle the defaults-drift tests compare the SoT
/// snapshot against: real SDK objects, dumped wide.
///
/// Types are named `*WideDefaults` so they do not clash with the narrow production types of the
/// same name, which the test target sees via `@testable import`.

extension ScanditCaptureCore.RectangularViewfinderStyle: Swift.CaseIterable {
    public static var allCases: [RectangularViewfinderStyle] {
        [.rounded, .square]
    }
}

struct RectangularViewfinderDefaults: DefaultsEncodable {
    func toEncodable() -> [String: Any?] {
        let allViewFinders = Dictionary(
            uniqueKeysWithValues: RectangularViewfinderStyle.allCases.map {
                (
                    $0.jsonString,
                    EncodableRectangularViewfinder(viewfinder: RectangularViewfinder(style: $0)).toEncodable()
                )
            }
        )

        return [
            "defaultStyle": RectangularViewfinderStyle.rounded.jsonString,
            "styles": allViewFinders,
        ]
    }
}

struct CameraWideDefaults: DefaultsEncodable {
    private let cameraSettingsDefaults: EncodableCameraSettings
    private let defaultPosition: CameraPosition?
    private let availablePositions: [CameraPosition]?

    init(
        cameraSettingsDefaults: EncodableCameraSettings,
        defaultPosition: CameraPosition?,
        availablePositions: [CameraPosition]?
    ) {
        self.cameraSettingsDefaults = cameraSettingsDefaults
        self.defaultPosition = defaultPosition
        self.availablePositions = availablePositions
    }

    func toEncodable() -> [String: Any?] {
        [
            "Settings": cameraSettingsDefaults.toEncodable(),
            CameraDefaults.Keys.defaultPosition: defaultPosition?.jsonString,
            CameraDefaults.Keys.availablePositions: availablePositions?.map { $0.jsonString },
        ]
    }
}

public struct ZoomSwitchControlWideDefaults: DefaultsEncodable {
    private let control: ZoomSwitchControl

    public init(control: ZoomSwitchControl) {
        self.control = control
    }

    public func toEncodable() -> [String: Any?] {
        [
            "orientation": control.orientation.jsonString,
            "isAlwaysExpanded": control.isAlwaysExpanded,
            "isExpanded": control.isExpanded,
            ZoomSwitchControlDefaults.Keys.accessibilityLabel: control.accessibilityLabel,
            "accessibilityHint": control.accessibilityHint,
        ]
    }
}

struct CoreWideDefaults: DefaultsEncodable {
    private let cameraDefaults: CameraWideDefaults
    private let dataCaptureViewDefaults: DataCaptureViewDefaults
    private let rectangularViewfinderDefaults: RectangularViewfinderDefaults
    private let aimerViewfinderDefauls: EncodableAimerViewfinder
    private let brushDefaults: EncodableBrush
    private let laserlineViewfinderDefaults: LaserlineViewfinderDefaults
    private let zoomSwitchControlDefaults: ZoomSwitchControlWideDefaults
    private let macroModeControlDefaults: MacroModeControlDefaults

    init(
        cameraDefaults: CameraWideDefaults,
        dataCaptureViewDefaults: DataCaptureViewDefaults,
        rectangularViewfinderDefaults: RectangularViewfinderDefaults,
        aimerViewfinderDefauls: EncodableAimerViewfinder,
        brushDefaults: EncodableBrush,
        laserlineViewfinderDefaults: LaserlineViewfinderDefaults,
        zoomSwitchControlDefaults: ZoomSwitchControlWideDefaults,
        macroModeControlDefaults: MacroModeControlDefaults
    ) {
        self.cameraDefaults = cameraDefaults
        self.dataCaptureViewDefaults = dataCaptureViewDefaults
        self.rectangularViewfinderDefaults = rectangularViewfinderDefaults
        self.aimerViewfinderDefauls = aimerViewfinderDefauls
        self.brushDefaults = brushDefaults
        self.laserlineViewfinderDefaults = laserlineViewfinderDefaults
        self.zoomSwitchControlDefaults = zoomSwitchControlDefaults
        self.macroModeControlDefaults = macroModeControlDefaults
    }

    func toEncodable() -> [String: Any?] {
        [
            CoreDefaults.Keys.version: DataCaptureVersion.version(),
            CoreDefaults.Keys.deviceID: DataCaptureContext.deviceID,
            CoreDefaults.Keys.camera: cameraDefaults.toEncodable(),
            "DataCaptureView": dataCaptureViewDefaults.toEncodable(),
            "RectangularViewfinder": rectangularViewfinderDefaults.toEncodable(),
            "AimerViewfinder": aimerViewfinderDefauls.toEncodable(),
            "Brush": brushDefaults.toEncodable(),
            "LaserlineViewfinder": laserlineViewfinderDefaults.toEncodable(),
            CoreDefaults.Keys.zoomSwitchControl: zoomSwitchControlDefaults.toEncodable(),
            CoreDefaults.Keys.macroModeControl: macroModeControlDefaults.toEncodable(),
        ]
    }

    static let shared: CoreWideDefaults = {
        let cameraDefaults = CameraWideDefaults(
            cameraSettingsDefaults: EncodableCameraSettings(cameraSettings: CameraSettings()),
            defaultPosition: Camera.default?.position,
            availablePositions: CameraPosition.allCases.compactMap { Camera(position: $0)?.position }
        )
        return CoreWideDefaults(
            cameraDefaults: cameraDefaults,
            dataCaptureViewDefaults: DataCaptureViewDefaults(view: DataCaptureView(frame: .zero)),
            rectangularViewfinderDefaults: RectangularViewfinderDefaults(),
            aimerViewfinderDefauls: EncodableAimerViewfinder(viewfinder: AimerViewfinder()),
            brushDefaults: EncodableBrush(brush: .transparent),
            laserlineViewfinderDefaults: LaserlineViewfinderDefaults(viewfinder: LaserlineViewfinder()),
            zoomSwitchControlDefaults: ZoomSwitchControlWideDefaults(control: ZoomSwitchControl()),
            macroModeControlDefaults: MacroModeControlDefaults(control: MacroModeControl())
        )
    }()
}
