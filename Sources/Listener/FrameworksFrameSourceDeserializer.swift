/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

open class FrameworksFrameSourceDeserializer: NSObject {
    private let frameSourceListener: FrameSourceListener
    private let torchListener: TorchListener
    private var cameraDesiredState: FrameSourceState = FrameSourceState.off

    public init(frameSourceListener: FrameSourceListener, torchListener: TorchListener) {
        self.frameSourceListener = frameSourceListener
        self.torchListener = torchListener
    }

    var camera: Camera? {
        willSet {
            camera?.removeListener(frameSourceListener)
            camera?.removeTorchListener(torchListener)
        }
        didSet {
            camera?.addListener(frameSourceListener)
            camera?.addTorchListener(torchListener)
        }
    }

    private var imageFrameSource: ImageFrameSource? {
        willSet {
            imageFrameSource?.removeListener(frameSourceListener)
        }
        didSet {
            imageFrameSource?.addListener(frameSourceListener)
        }
    }

    public func releaseCurrentCamera() {
        camera?.switch(toDesiredState: FrameSourceState.off)
        camera = nil
        imageFrameSource = nil
    }

    public func switchCameraToState(newState: FrameSourceState, completionHandler: ((Bool) -> Void)?) {
        self.cameraDesiredState = newState
        if camera == nil && imageFrameSource == nil {
            completionHandler?(true)
            return
        }
        camera?.switch(toDesiredState: newState, completionHandler: completionHandler)
        imageFrameSource?.switch(toDesiredState: newState, completionHandler: completionHandler)
    }
}

extension FrameworksFrameSourceDeserializer: FrameSourceDeserializerDelegate {
    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didStartDeserializingFrameSource frameSource: FrameSource,
                                 from jsonValue: JSONValue) {}

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didFinishDeserializingFrameSource frameSource: FrameSource,
                                        from jsonValue: JSONValue) {
        self.camera = frameSource as? Camera
        if let camera = camera {
            self.imageFrameSource = nil
            if jsonValue.containsKey("desiredTorchState") {
                var torchState: TorchState = .off
                SDCTorchStateFromJSONString(jsonValue.string(forKey: "desiredTorchState"), &torchState)
                camera.desiredTorchState = torchState
            }
            camera.switch(toDesiredState: cameraDesiredState)
            self.camera = camera
        } else {
            self.camera = nil
            self.imageFrameSource = frameSource as? ImageFrameSource
            guard let imageFrameSource = self.imageFrameSource else {
            	return
            }
            imageFrameSource.switch(toDesiredState: cameraDesiredState)
        }
    }

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didStartDeserializingCameraSettings settings: CameraSettings,
                                 from jsonValue: JSONValue) {}

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didFinishDeserializingCameraSettings settings: CameraSettings,
                                 from jsonValue: JSONValue) {}
}
