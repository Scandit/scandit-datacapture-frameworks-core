/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

/// Outcome of adding a frame to the tracked sequence frame source — kept distinct so callers
/// can report the actual failure cause instead of collapsing them into one message.
public enum SequenceFrameSourceAddFrameResult {
    case added
    case noSuchFrameSource
    case invalidFrameData
}

public protocol FrameSourceHandler {
    func onNewFrameSourceDeserialized(frameSource: FrameSource, json: JSONValue)

    /// Creates (or reuses, when the incoming `id` matches the currently tracked one) a native
    /// SequenceFrameSource from the frameworks frame-source JSON. The `sequence` type is not
    /// supported by the native frame-source deserializer, so the frameworks layer constructs it
    /// directly from the JSON before it is set on the context.
    func deserializeSequenceFrameSource(json: String) -> FrameSource?

    /// Adds an NV21 frame to the tracked sequence frame source.
    func addFrameToSequenceFrameSource(
        frameSourceId: String,
        width: Int,
        height: Int,
        frameData: Data
    ) -> SequenceFrameSourceAddFrameResult

    /// Returns the current state of the tracked sequence frame source with the given id, or
    /// nil when no sequence frame source with that id is currently tracked.
    func getSequenceFrameSourceState(frameSourceId: String) -> FrameSourceState?

    /// Called when the context's frame source changed outside the frameworks deserializer —
    /// e.g. the native CameraSwitchControl swapping cameras. Re-targets the tracked frame
    /// source so state listeners and switchCameraToState follow the actually-active camera.
    func onFrameSourceChanged(frameSource: FrameSource?)

    func switchCameraToState(newState: FrameSourceState, whenDone: ((Bool) -> Void)?)

    func getCameraStateByPosition(cameraPosition: String) -> FrameSourceState?

    func getIsTorchAvailableByPosition(cameraPosition: String) -> Bool?

    var currentCameraState: FrameSourceState? { get }

    var currentCameraDesiredState: FrameSourceState? { get }

    func releaseCamera()

    func addTorchStateListener()

    func removeTorchStateListener()

    func addMacroModeListener()

    func removeMacroModeListener()

    func addZoomListener()

    func removeZoomListener()
}
