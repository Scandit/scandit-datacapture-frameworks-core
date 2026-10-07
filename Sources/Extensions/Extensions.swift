/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation

public extension Dictionary {
    func encodeToJSONString() -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding dictionary to JSON: \(error)")
            return nil
        }
    }
}

public extension Dictionary where Key == String, Value == Any {
    var viewId: Int {
        self["viewId"] as? Int ?? 0
    }

    var modeId: Int {
        self["modeId"] as? Int ?? 0
    }

    var dataCaptureViewId: Int {
        self["dataCaptureViewId"] as? Int ?? 0
    }
}
