/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct LaserlineViewfinderDefaults: DefaultsEncodable {
    private let viewfinder: LaserlineViewfinder

    init(viewfinder: LaserlineViewfinder) {
        self.viewfinder = viewfinder
    }

    func toEncodable() -> [String: Any?] {
        [
            "width": viewfinder.width.jsonString,
            "enabledColor": viewfinder.enabledColor.sdcHexString,
            "disabledColor": viewfinder.disabledColor.sdcHexString
        ]
    }
}
