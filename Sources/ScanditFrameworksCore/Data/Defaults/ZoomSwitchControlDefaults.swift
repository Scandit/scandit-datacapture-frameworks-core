/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public struct ZoomSwitchControlDefaults {
    private let control: ZoomSwitchControl

    public init(control: ZoomSwitchControl) {
        self.control = control
    }

    /// The residual key of this block that a framework plugin cannot resolve statically: the
    /// localized accessibility label (it embeds the current zoom level).
    ///
    /// Every other zoom-switch default ships as a generated static file.
    public func toDynamicEncodable() -> [String: Any?] {
        [Keys.accessibilityLabel: control.accessibilityLabel]
    }

    /// The localized key of this block - the only one a framework plugin cannot resolve
    /// statically (it embeds the current zoom level).
    public enum Keys {
        public static let accessibilityLabel = "accessibilityLabel"
    }
}
