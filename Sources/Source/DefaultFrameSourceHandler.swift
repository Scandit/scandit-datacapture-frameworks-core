/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class DefaultFrameSourceHandler: FrameSourceHandler {
    private let frameSourceListener: FrameworksFrameSourceListener
    private let torchStateListener: FrameworksTorchListener
    private let macroModeListener: FrameworksMacroModeListener

    private var camera: Camera? {
        willSet {
            camera?.removeListener(frameSourceListener)
        }
        didSet {
            camera?.addListener(frameSourceListener)
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
        camera?.desiredState
    }

    public var currentCameraState: FrameSourceState? {
        camera?.currentState
    }

    public init(
        frameSourceListener: FrameworksFrameSourceListener,
        torchStateListener: FrameworksTorchListener,
        macroModeListener: FrameworksMacroModeListener
    ) {
        self.frameSourceListener = frameSourceListener
        self.torchStateListener = torchStateListener
        self.macroModeListener = macroModeListener
    }

    public func onNewFrameSourceDeserialized(frameSource: FrameSource, json: JSONValue) {
        if let camera = frameSource as? Camera {
            self.camera = camera
            self.imageFrameSource = nil

            applyTorchStateFromJson(camera: camera, json: json)
            applyDesiredStateFromJson(frameSource: camera, json: json)
            checkAndSetTorchStateListener(camera: camera, json: json)
            checkAndSetMacroModeListener(camera: camera, json: json)
        } else if let imageFrameSource = frameSource as? ImageFrameSource {
            self.imageFrameSource = imageFrameSource
            self.camera = nil

            applyDesiredStateFromJson(frameSource: imageFrameSource, json: json)
        }
    }

    private func applyTorchStateFromJson(camera: Camera, json: JSONValue) {
        if json.containsKey(DefaultFrameSourceHandler.desiredTorchStateKey) {
            var torchState: TorchState = .off
            SDCTorchStateFromJSONString(
                json.string(forKey: DefaultFrameSourceHandler.desiredTorchStateKey),
                &torchState
            )
            camera.desiredTorchState = torchState
        }
    }

    private func checkAndSetTorchStateListener(camera: Camera, json: JSONValue) {
        if json.containsKey(DefaultFrameSourceHandler.hasTorchStateListenersKey) {
            if json.bool(forKey: DefaultFrameSourceHandler.hasTorchStateListenersKey) {
                camera.addTorchListener(torchStateListener)
            } else {
                camera.removeTorchListener(torchStateListener)
            }
        }
    }

    private func checkAndSetMacroModeListener(camera: Camera, json: JSONValue) {
        if json.containsKey(DefaultFrameSourceHandler.hasMacroModeListenersKey) {
            if json.bool(forKey: DefaultFrameSourceHandler.hasMacroModeListenersKey) {
                camera.addMacroModeListener(macroModeListener)
            } else {
                camera.removeMacroModeListener(macroModeListener)
            }
        }
    }

    private func applyDesiredStateFromJson(frameSource: FrameSource, json: JSONValue) {
        if json.containsKey(DefaultFrameSourceHandler.desiredStateKey) {
            var frameState: FrameSourceState = .off
            SDCFrameSourceStateFromJSONString(
                json.string(forKey: DefaultFrameSourceHandler.desiredStateKey),
                &frameState
            )
            frameSource.switch(toDesiredState: frameState)
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

    public func addTorchStateListener() {
        camera?.addTorchListener(torchStateListener)
    }

    public func removeTorchStateListener() {
        camera?.removeTorchListener(torchStateListener)
    }

    public func addMacroModeListener() {
        camera?.addMacroModeListener(macroModeListener)
    }

    public func removeMacroModeListener() {
        camera?.removeMacroModeListener(macroModeListener)
    }

    // MARK: - Private Constants

    private static let desiredTorchStateKey = "desiredTorchState"
    private static let desiredStateKey = "desiredState"
    private static let hasTorchStateListenersKey = "hasTorchStateListeners"
    private static let hasMacroModeListenersKey = "hasMacroModeListeners"
}
