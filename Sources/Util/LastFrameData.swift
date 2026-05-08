/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public final class LastFrameData {
    public static let shared = LastFrameData()

    private init() {}

    private var _frameData: FrameData?

    public var frameData: FrameData? {
        get {
            queue.sync {
                _frameData
            }
        }
        set {
            queue.async(flags: .barrier) {
                self._frameData = newValue
            }
        }
    }

    private var queue = DispatchQueue(label: "com.scandit.frameworks.lastframedata-queue",
                                      attributes: .concurrent)

    public func getLastFrameDataJSON(result: @escaping (String?) -> Void) {
        result(queue.sync {
            frameData?.jsonString
        })
    }
    
    public func getLastFrameDataBytes(result: @escaping ([String: Any?]?) -> Void) {
        result(queue.sync {
            frameData?.toEncodable()
        })
    }
}

private extension FrameData {
    func toEncodable() -> [String: Any?] {
        return  [
            "imageBuffers": self.imageBuffers.compactMap { $0.toEncodable() },
            "orientation": 90,
        ]
    }
}

private extension ImageBuffer {
    func toEncodable() -> [String: Any?] {
        return  [
            "width": self.width,
            "height": self.height,
            "data": self.image?.pngData()
        ]
    }
}
