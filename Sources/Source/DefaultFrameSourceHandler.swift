/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class DefaultFrameSourceHandler: FrameSourceHandler {
    private let frameSourceListener: FrameworksFrameSourceListener

    private var camera: Camera? {
        willSet {
            camera?.removeListener(frameSourceListener)
            camera?.removeTorchListener(frameSourceListener)
        }
        didSet {
            camera?.addListener(frameSourceListener)
            camera?.addTorchListener(frameSourceListener)
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

    public var currentCameraDesiredState: FrameSourceState? {
        return camera?.desiredState
    }

    public var currentCameraState: FrameSourceState? {
        return camera?.currentState
    }

    public init(frameSourceListener: FrameworksFrameSourceListener) {
        self.frameSourceListener = frameSourceListener
    }

    public func onNewFrameSourceDeserialized(frameSource: FrameSource, json: JSONValue) {
        if let camera = frameSource as? Camera {
            self.camera = camera
            self.imageFrameSource = nil

            if json.containsKey(DefaultFrameSourceHandler.desiredTorchStateKey) {
                var torchState: TorchState = .off
                SDCTorchStateFromJSONString(json.string(forKey: DefaultFrameSourceHandler.desiredTorchStateKey), &torchState)
                camera.desiredTorchState = torchState
            }
            if json.containsKey(DefaultFrameSourceHandler.desiredStateKey) {
                var frameState: FrameSourceState = .off
                SDCFrameSourceStateFromJSONString(json.string(forKey: DefaultFrameSourceHandler.desiredStateKey), &frameState)
                camera.switch(toDesiredState: frameState)
            }
        } else if let imageFrameSource = frameSource as? ImageFrameSource {
            self.imageFrameSource = imageFrameSource
            self.camera = nil

            if json.containsKey(DefaultFrameSourceHandler.desiredStateKey) {
                var frameState: FrameSourceState = .off
                SDCFrameSourceStateFromJSONString(json.string(forKey: DefaultFrameSourceHandler.desiredStateKey), &frameState)
                imageFrameSource.switch(toDesiredState: frameState)
            }
        }
    }

    public func switchCameraToState(newState: FrameSourceState, whenDone: ((Bool) -> Void)?) {
        if self.camera == nil && self.imageFrameSource == nil {
            whenDone?(true)
            return
        }

        camera?.switch(toDesiredState: newState, completionHandler: whenDone)
        imageFrameSource?.switch(toDesiredState: newState, completionHandler: whenDone)
    }

    public func getCameraStateByPosition(cameraPosition: String) -> FrameSourceState? {
        var position = CameraPosition.unspecified
        SDCCameraPositionFromJSONString(cameraPosition, &position)

        guard let camera = camera, camera.position == position else {
            return nil
        }

        return camera.currentState
    }

    public func getIsTorchAvailableByPosition(cameraPosition: String) -> Bool? {
        var position = CameraPosition.unspecified
        SDCCameraPositionFromJSONString(cameraPosition, &position)

        guard let camera = camera, camera.position == position else {
            return nil
        }

        return camera.isTorchAvailable
    }

    public func releaseCamera() {
        camera?.switch(toDesiredState: .off)
        camera = nil
        imageFrameSource = nil
    }

    // MARK: - Private Constants

    private static let desiredTorchStateKey = "desiredTorchState"
    private static let desiredStateKey = "desiredState"
}
