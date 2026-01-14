/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public struct EncodableBrush: DefaultsEncodable {
    private let brush: Brush

    public init(brush: Brush) {
        self.brush = brush
    }

    public func toEncodable() -> [String: Any?] {
        [
            "fillColor": brush.fillColor.sdcHexString,
            "strokeColor": brush.strokeColor.sdcHexString,
            "strokeWidth": brush.strokeWidth
        ]
    }
}
