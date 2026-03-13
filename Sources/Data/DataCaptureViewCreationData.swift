/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public struct OverlayEntry {
    /// Identity key in the form `type:modeId`, used for diffing overlays.
    public let key: String
    /// The overlay type extracted from `key` (the part before `:`).
    public let type: String
    /// The raw JSON string passed to the deserialization dispatcher.
    public let jsonString: String

    static func from(overlayDict: [String: Any]) -> OverlayEntry? {
        guard let type = overlayDict["type"] as? String,
            let data = try? JSONSerialization.data(withJSONObject: overlayDict),
            let jsonString = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        let modeId = overlayDict["modeId"] as? Int ?? -1
        return OverlayEntry(key: "\(type):\(modeId)", type: type, jsonString: jsonString)
    }
}

public class DataCaptureViewCreationData {
    let viewId: Int
    let parentId: Int?
    let viewJson: String
    let overlays: [OverlayEntry]

    private init(
        viewId: Int,
        parentId: Int?,
        viewJson: String,
        overlays: [OverlayEntry]
    ) {
        self.viewId = viewId
        self.parentId = parentId
        self.viewJson = viewJson
        self.overlays = overlays
    }

    static func fromJson(_ jsonString: String) -> DataCaptureViewCreationData {
        guard let jsonData = jsonString.data(using: .utf8),
            var json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            // Return default values if JSON parsing fails
            return DataCaptureViewCreationData(
                viewId: 0,
                parentId: nil,
                viewJson: "{}",
                overlays: []
            )
        }

        let overlays = getOverlaysFromViewJson(&json)

        return DataCaptureViewCreationData(
            viewId: json[Constants.viewIdKey] as? Int ?? 0,
            parentId: json[Constants.parentIdKey] as? Int,
            viewJson: convertToJsonString(json) ?? "{}",
            overlays: overlays
        )
    }

    private static func getOverlaysFromViewJson(_ json: inout [String: Any]) -> [OverlayEntry] {
        var overlays: [OverlayEntry] = []

        if let overlayDicts = json[Constants.overlaysKey] as? [[String: Any]] {
            for dict in overlayDicts {
                if let entry = OverlayEntry.from(overlayDict: dict) {
                    overlays.append(entry)
                }
            }
        }
        json.removeValue(forKey: Constants.overlaysKey)
        return overlays
    }

    private static func convertToJsonString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    private struct Constants {
        static let viewIdKey = "viewId"
        static let parentIdKey = "parentId"
        static let overlaysKey = "overlays"
    }
}
