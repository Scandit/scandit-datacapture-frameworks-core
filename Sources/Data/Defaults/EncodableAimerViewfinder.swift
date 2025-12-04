/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct EncodableAimerViewfinder: DefaultsEncodable {
    private let viewfinder: AimerViewfinder

    init(viewfinder: AimerViewfinder) {
        self.viewfinder = viewfinder
    }

    func toEncodable() -> [String: Any?] {
        [
            "frameColor": viewfinder.frameColor.sdcHexString,
            "dotColor": viewfinder.dotColor.sdcHexString
        ]
    }
}
