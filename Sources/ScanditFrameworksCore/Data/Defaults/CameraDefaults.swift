/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct CameraDefaults {
    private let defaultPosition: CameraPosition?
    private let availablePositions: [CameraPosition]?

    init(defaultPosition: CameraPosition?, availablePositions: [CameraPosition]?) {
        self.defaultPosition = defaultPosition
        self.availablePositions = availablePositions
    }

    /// The residual keys of this block that a framework plugin cannot resolve statically: the
    /// device-probed default and available camera positions. The camera settings themselves
    /// ship as a generated static file.
    func toDynamicEncodable() -> [String: Any?] {
        [
            Keys.defaultPosition: defaultPosition?.jsonString,
            Keys.availablePositions: availablePositions?.map { $0.jsonString },
        ]
    }

    enum Keys {
        static let defaultPosition = "defaultPosition"
        static let availablePositions = "availablePositions"
    }
}
