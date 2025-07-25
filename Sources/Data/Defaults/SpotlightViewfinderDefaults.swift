/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct SpotlightViewfinderDefaults: DefaultsEncodable {
    func toEncodable() -> [String: Any?] {
        [
            "size": "{\"height\":{\"unit\":\"fraction\",\"value\":0.32499998807907104},\"width\":{\"unit\":\"fraction\",\"value\":0.800000011920929}}",
            "enabledBorderColor": "ffffffff",
            "disabledBorderColor": "ffffffff",
            "backgroundColor": "0000007f"
        ]
    }
}
