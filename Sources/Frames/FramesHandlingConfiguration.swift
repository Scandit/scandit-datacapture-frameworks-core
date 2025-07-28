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
    let autoRotateImages: Bool

    init(isFileSystemCacheEnabled: Bool, imageQuality: Int, autoRotateImages: Bool) {
        self.isFileSystemCacheEnabled = isFileSystemCacheEnabled
        self.imageQuality = imageQuality
        self.autoRotateImages = autoRotateImages
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
                    
                    guard let frameSettings = settingsJson["frameDataSettings"] as? [String: Any] else {
                        return createDefaultConfiguration()
                    }

                    let isFileSystemCacheEnabled = frameSettings["sc_frame_isFileSystemCacheEnabled"] as? Bool ?? false
                    let imageQuality = frameSettings["sc_frame_imageQuality"] as? Int ?? 100
                    let autoRotateImages = frameSettings["sc_frame_autoRotate"] as? Bool ?? false

                    return FramesHandlingConfiguration(
                        isFileSystemCacheEnabled: isFileSystemCacheEnabled,
                        imageQuality: imageQuality,
                        autoRotateImages: autoRotateImages

                    )
                }
            } catch {
                print(
                    "Error parsing JSON: \(error)"
                )
            }
        }

        return createDefaultConfiguration()
    }

    public static func createDefaultConfiguration() -> FramesHandlingConfiguration {
        return FramesHandlingConfiguration(
            isFileSystemCacheEnabled: false,
            imageQuality: 100,
            autoRotateImages: false
        )
    }
}
