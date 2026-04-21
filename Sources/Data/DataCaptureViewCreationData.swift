/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class DataCaptureViewCreationData {
    let viewId: Int
    let parentId: Int?
    let viewJson: String
    let overlaysJson: [String]

    private init(
        viewId: Int,
        parentId: Int?,
        viewJson: String,
        overlaysJson: [String]
    ) {
        self.viewId = viewId
        self.parentId = parentId
        self.viewJson = viewJson
        self.overlaysJson = overlaysJson
    }

    static func fromJson(_ jsonString: String) -> DataCaptureViewCreationData {
        guard let jsonData = jsonString.data(using: .utf8),
              var json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            // Return default values if JSON parsing fails
            return DataCaptureViewCreationData(
                viewId: 0,
                parentId: nil,
                viewJson: "{}",
                overlaysJson: []
            )
        }

        let overlays = getOverlaysFromViewJson(&json)

        return DataCaptureViewCreationData(
            viewId: json[Constants.VIEW_ID_KEY] as? Int ?? 0,
            parentId: json[Constants.PARENT_ID_KEY] as? Int,
            viewJson: convertToJsonString(json) ?? "{}",
            overlaysJson: overlays
        )
    }

    private static func getOverlaysFromViewJson(_ json: inout [String: Any]) -> [String] {
        var overlays = [String]()

        if let overlaysJson = json[Constants.OVERLAYS_KEY] as? [[String: Any]] {
            for overlay in overlaysJson {
                if let overlayData = try? JSONSerialization.data(withJSONObject: overlay, options: []),
                   let overlayString = String(data: overlayData, encoding: .utf8) {
                    overlays.append(overlayString)
                }
            }
        }
        json.removeValue(forKey: Constants.OVERLAYS_KEY)
        return overlays
    }

    private static func convertToJsonString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    private struct Constants {
        static let VIEW_ID_KEY = "viewId"
        static let PARENT_ID_KEY = "parentId"
        static let OVERLAYS_KEY = "overlays"
    }
}
