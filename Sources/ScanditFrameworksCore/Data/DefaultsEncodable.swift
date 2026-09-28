/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation

public protocol DefaultsEncodable {
    func toEncodable() -> [String: Any?]
    var stringValue: String { get }
}

public extension DefaultsEncodable {
    var stringValue: String {
        var data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: toEncodable(), options: [])
        } catch {
            Log.error(error)
            fatalError()
        }
        guard let string = String(data: data, encoding: .utf8) else {
            Log.error("Failed to encode defaults to UTF8 string")
            return "{}"
        }
        return string
    }
}
