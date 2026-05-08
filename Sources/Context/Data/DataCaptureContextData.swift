/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

internal struct DataCaptureContextData {
    let licenseKey: String
    let deviceName: String?
    let framework: String?
    let frameworkVersion: String?
    let externalId: String?
    let frameSource: String?
    let settings: [String: Any]?

    static func from(jsonString: String) throws -> DataCaptureContextData {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "DataCaptureContext", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string."])
        }
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let jsonDict = jsonObject as! [String: Any]

        
        let licenseKey = jsonDict["licenseKey"] as! String
        let deviceName = jsonDict["deviceName"] as? String
        let framework = jsonDict["framework"] as? String
        let frameworkVersion = jsonDict["frameworkVersion"] as? String
        let externalId = jsonDict["externalId"] as? String
        let frameSource = (jsonDict["frameSource"] as? [String: Any])?.encodeToJSONString()
        let settings = jsonDict["settings"] as? [String: Any]

        return DataCaptureContextData(
            licenseKey: licenseKey,
            deviceName: deviceName,
            framework: framework,
            frameworkVersion: frameworkVersion,
            externalId: externalId,
            frameSource: frameSource,
            settings: settings
        )
    }
}

extension Dictionary where Key == String, Value == Any {
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        for (key, value) in self {
            if let dictValue = value as? [String: Any] {
                map[key] = dictValue.toMap()
            } else {
                map[key] = value
            }
        }
        return map
    }
}

