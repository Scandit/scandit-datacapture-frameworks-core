/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

open class FrameworksFrameSourceDeserializer: NSObject, FrameSourceDeserializerDelegate {
    private let frameSourceHandler: FrameSourceHandler

    public init(frameSourceHandler: FrameSourceHandler) {
        self.frameSourceHandler = frameSourceHandler
    }
    
    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didStartDeserializingFrameSource frameSource: FrameSource,
                                 from jsonValue: JSONValue) {}

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didFinishDeserializingFrameSource frameSource: FrameSource,
                                        from jsonValue: JSONValue) {
        
        self.frameSourceHandler.onNewFrameSourceDeserialized(frameSource: frameSource, json: jsonValue)
    }

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didStartDeserializingCameraSettings settings: CameraSettings,
                                 from jsonValue: JSONValue) {}

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didFinishDeserializingCameraSettings settings: CameraSettings,
                                 from jsonValue: JSONValue) {}
}
