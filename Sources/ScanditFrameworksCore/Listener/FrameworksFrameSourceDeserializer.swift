/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore
import ScanditCaptureCoreDeserializer

open class FrameworksFrameSourceDeserializer: NSObject, FrameSourceDeserializerDelegate {
    private let frameSourceHandler: FrameSourceHandler

    public init(frameSourceHandler: FrameSourceHandler) {
        self.frameSourceHandler = frameSourceHandler
    }

    /// Deserializes the frame-source JSON. The `sequence` type is not supported by the native
    /// FrameSourceDeserializer (it only accepts `camera` and `image`), so it is intercepted here
    /// and constructed by the frameworks layer instead; every other type is delegated to the
    /// given native deserializer.
    public func frameSource(
        fromJson json: String,
        nativeDeserializer: FrameSourceDeserializer
    ) throws -> FrameSource? {
        let type = (try? JSONSerialization.jsonObject(with: Data(json.utf8)))
            .flatMap { $0 as? [String: Any] }
            .flatMap { $0["type"] as? String }

        if type == "sequence" {
            return frameSourceHandler.deserializeSequenceFrameSource(json: json)
        }
        return try nativeDeserializer.frameSource(fromJSONString: json)
    }

    public func frameSourceDeserializer(
        _ deserializer: FrameSourceDeserializer,
        didStartDeserializingFrameSource frameSource: FrameSource,
        from jsonValue: JSONValue
    ) {}

    public func frameSourceDeserializer(
        _ deserializer: FrameSourceDeserializer,
        didFinishDeserializingFrameSource frameSource: FrameSource,
        from jsonValue: JSONValue
    ) {

        self.frameSourceHandler.onNewFrameSourceDeserialized(frameSource: frameSource, json: jsonValue)
    }

    public func frameSourceDeserializer(
        _ deserializer: FrameSourceDeserializer,
        didStartDeserializingCameraSettings settings: CameraSettings,
        from jsonValue: JSONValue
    ) {}

    public func frameSourceDeserializer(
        _ deserializer: FrameSourceDeserializer,
        didFinishDeserializingCameraSettings settings: CameraSettings,
        from jsonValue: JSONValue
    ) {}
}
