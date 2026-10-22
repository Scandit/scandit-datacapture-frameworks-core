/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

extension ScanditCaptureCore.CameraPosition: Swift.CaseIterable {
    public static var allCases: [CameraPosition] {
        [.worldFacing, .userFacing, .unspecified]
    }
}

struct CoreDefaults {
    private let cameraDefaults: CameraDefaults
    private let zoomSwitchControlDefaults: ZoomSwitchControlDefaults
    private let macroModeControlDefaults: MacroModeControlDefaults

    init(
        cameraDefaults: CameraDefaults,
        zoomSwitchControlDefaults: ZoomSwitchControlDefaults,
        macroModeControlDefaults: MacroModeControlDefaults
    ) {
        self.cameraDefaults = cameraDefaults
        self.zoomSwitchControlDefaults = zoomSwitchControlDefaults
        self.macroModeControlDefaults = macroModeControlDefaults
    }

    /// Top-level keys of the dynamic defaults payload. The Dart side reads
    /// `defaults['Version'] as String`, so a renamed literal here throws at plugin load.
    enum Keys {
        static let version = "Version"
        static let deviceID = "deviceID"
        static let camera = "Camera"
        static let zoomSwitchControl = "ZoomSwitchControl"
        static let macroModeControl = "MacroModeControl"
    }

    /// The residual set of core defaults that a framework plugin cannot resolve statically: the
    /// SDK version, the device id and the device-probed camera positions, the localized
    /// ZoomSwitchControl accessibility label, and the MacroModeControl block (localized texts and
    /// asset handles). Every other core default ships as a generated static file.
    func toDynamicEncodable() -> [String: Any?] {
        [
            Keys.version: DataCaptureVersion.version(),
            Keys.deviceID: DataCaptureContext.deviceID,
            Keys.camera: cameraDefaults.toDynamicEncodable(),
            Keys.zoomSwitchControl: zoomSwitchControlDefaults.toDynamicEncodable(),
            Keys.macroModeControl: macroModeControlDefaults.toEncodable(),
        ]
    }

    static let shared: CoreDefaults = {
        CoreDefaults(
            cameraDefaults: CameraDefaults(
                defaultPosition: Camera.default?.position,
                availablePositions: CameraPosition.allCases.compactMap { Camera(position: $0)?.position }
            ),
            zoomSwitchControlDefaults: ZoomSwitchControlDefaults(control: ZoomSwitchControl()),
            macroModeControlDefaults: MacroModeControlDefaults(control: MacroModeControl())
        )
    }()
}
