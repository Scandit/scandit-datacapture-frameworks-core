/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public struct ZoomSwitchControlDefaults: DefaultsEncodable {
    private let control: ZoomSwitchControl

    public init(control: ZoomSwitchControl) {
        self.control = control
    }

    public func toEncodable() -> [String: Any?] {
        [
            "orientation": control.orientation.jsonString,
            "isAlwaysExpanded": control.isAlwaysExpanded,
            "isExpanded": control.isExpanded,
            "accessibilityLabel": control.accessibilityLabel,
            "accessibilityHint": control.accessibilityHint,
        ]
    }
}
