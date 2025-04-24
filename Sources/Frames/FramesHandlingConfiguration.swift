/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public class FramesHandlingConfiguration {

    let isFileSystemCacheEnabled: Bool
    let imageQuality: Int

    init(isFileSystemCacheEnabled: Bool, imageQuality: Int) {
        self.isFileSystemCacheEnabled = isFileSystemCacheEnabled
        self.imageQuality = imageQuality
    }
    
    public static func create(
        contextCreationJson: String
    ) -> FramesHandlingConfiguration {
        if let jsonData = contextCreationJson.data(
            using: .utf8
        ) {
            do {
                if let json = try JSONSerialization.jsonObject(
                    with: jsonData,
                    options: []
                ) as? [String: Any],
                   let settingsJson = json["settings"] as? [String: Any] {
                    
                    let isFileSystemCacheEnabled = settingsJson["sc_frame_isFileSystemCacheEnabled"] as? Bool ?? false
                    let imageQuality = settingsJson["sc_frame_imageQuality"] as? Int ?? 100
                    
                    return FramesHandlingConfiguration(
                        isFileSystemCacheEnabled: isFileSystemCacheEnabled,
                        imageQuality: imageQuality
                    )
                }
            } catch {
                print(
                    "Error parsing JSON: \(error)"
                )
            }
        }
        
        return FramesHandlingConfiguration(
            isFileSystemCacheEnabled: false,
            imageQuality: 100
        )
    }
}
