/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct DataCaptureViewDefaults: DefaultsEncodable {
    private let view: DataCaptureView

    init(view: DataCaptureView) {
        self.view = view
    }

    func toEncodable() -> [String: Any?] {
        [
            "scanAreaMargins": view.scanAreaMargins.jsonString,
            "pointOfInterest": view.pointOfInterest.jsonString,
            "logoAnchor": view.logoAnchor.jsonString,
            "logoOffset": view.logoOffset.jsonString,
            "focusGesture": view.focusGesture?.jsonString,
            "zoomGesture": view.zoomGesture?.jsonString,
            "logoStyle": view.logoStyle.jsonString
        ]
    }
}
