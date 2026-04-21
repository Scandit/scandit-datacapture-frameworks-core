/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public protocol FrameSourceHandler {
    func onNewFrameSourceDeserialized(frameSource: FrameSource, json: JSONValue)

    func switchCameraToState(newState: FrameSourceState, whenDone: ((Bool) -> Void)?)

    func getCameraStateByPosition(cameraPosition: String) -> FrameSourceState?

    func getIsTorchAvailableByPosition(cameraPosition: String) -> Bool?

    var currentCameraState: FrameSourceState? { get }

    var currentCameraDesiredState: FrameSourceState? { get }

    func releaseCamera()
}
