/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import AVFoundation
import CoreMedia
import CoreVideo
import Foundation
import ScanditCaptureCore
import ScanditCaptureCoreDeserializer

public class DefaultFrameSourceHandler: FrameSourceHandler {
    private let frameSourceListener: FrameworksFrameSourceListener
    private let torchStateListener: FrameworksTorchListener
    private let macroModeListener: FrameworksMacroModeListener
    private let zoomListener: FrameworksZoomListener

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

    private var sequenceFrameSource: SequenceFrameSource? {
        willSet {
            sequenceFrameSource?.removeListener(frameSourceListener)
        }
        didSet {
            sequenceFrameSource?.addListener(frameSourceListener)
        }
    }

    private var sequenceFrameSourceId: String?

    // Monotonic presentation-timestamp counter (timescale 30) for frames fed via
    // addFrameToSequenceFrameSource. CMSampleBufferCreateReadyWithImageBuffer requires a valid
    // presentation timestamp; an invalid one fails and the frame would be silently dropped.
    private var nextPresentationTimeStampValue: Int64 = 0

    public var currentCameraDesiredState: FrameSourceState? {
        camera?.desiredState
    }

    public var currentCameraState: FrameSourceState? {
        camera?.currentState
    }

    public init(
        frameSourceListener: FrameworksFrameSourceListener,
        torchStateListener: FrameworksTorchListener,
        macroModeListener: FrameworksMacroModeListener,
        zoomListener: FrameworksZoomListener
    ) {
        self.frameSourceListener = frameSourceListener
        self.torchStateListener = torchStateListener
        self.macroModeListener = macroModeListener
        self.zoomListener = zoomListener
    }

    public func onFrameSourceChanged(frameSource: FrameSource?) {
        if let newCamera = frameSource as? Camera {
            guard camera !== newCamera else { return }
            camera = newCamera
            imageFrameSource = nil
            clearSequenceFrameSource()
        } else if let newImageFrameSource = frameSource as? ImageFrameSource {
            guard imageFrameSource !== newImageFrameSource else { return }
            imageFrameSource = newImageFrameSource
            camera = nil
            clearSequenceFrameSource()
        } else if let newSequenceFrameSource = frameSource as? SequenceFrameSource {
            guard sequenceFrameSource !== newSequenceFrameSource else { return }
            sequenceFrameSource = newSequenceFrameSource
            // A native-origin source (not deserialized from JS) has no known id.
            sequenceFrameSourceId = nil
            camera = nil
            imageFrameSource = nil
        } else {
            camera = nil
            imageFrameSource = nil
            clearSequenceFrameSource()
        }
    }

    public func onNewFrameSourceDeserialized(frameSource: FrameSource, json: JSONValue) {
        if let camera = frameSource as? Camera {
            let oldCameraId = self.camera.map { ObjectIdentifier($0) }
            NSLog(
                "[SDC32484] DefaultFrameSourceHandler.onNewFrameSourceDeserialized: entry newCamera=\(ObjectIdentifier(camera)), oldCamera=\(String(describing: oldCameraId))"
            )
            self.camera = camera
            self.imageFrameSource = nil
            clearSequenceFrameSource()

            applyTorchStateFromJson(camera: camera, json: json)
            applyDesiredStateFromJson(frameSource: camera, json: json)
            checkAndSetTorchStateListener(camera: camera, json: json)
            checkAndSetMacroModeListener(camera: camera, json: json)
            checkAndSetZoomListener(camera: camera, json: json)
            NSLog(
                "[SDC32484] DefaultFrameSourceHandler.onNewFrameSourceDeserialized: exit camera=\(ObjectIdentifier(camera)), desiredState=\(String(describing: camera.desiredState))"
            )
        } else if let imageFrameSource = frameSource as? ImageFrameSource {
            NSLog(
                "[SDC32484] DefaultFrameSourceHandler.onNewFrameSourceDeserialized: entry imageFrameSource, clearing camera"
            )
            self.imageFrameSource = imageFrameSource
            self.camera = nil
            clearSequenceFrameSource()

            applyDesiredStateFromJson(frameSource: imageFrameSource, json: json)
            NSLog("[SDC32484] DefaultFrameSourceHandler.onNewFrameSourceDeserialized: exit imageFrameSource")
        }
    }

    public func deserializeSequenceFrameSource(json: String) -> FrameSource? {
        guard let jsonData = json.data(using: .utf8),
            let jsonObject = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any]
        else {
            Log.error("Unable to parse the sequence frame source JSON.")
            return nil
        }

        let id = (jsonObject[DefaultFrameSourceHandler.idKey] as? String).flatMap { $0.isEmpty ? nil : $0 }

        // Reuse the tracked source when the id matches so unrelated context updates don't
        // recreate (and thereby reset) a sequence frame source that is being fed frames.
        let frameSource: SequenceFrameSource
        if let existing = sequenceFrameSource, id != nil, id == sequenceFrameSourceId {
            frameSource = existing
        } else {
            // Mirrors SDCCamera.defaultCamera's fallback priority (worldFacing first) so an
            // empty/unrecognized position string doesn't silently resolve to .unspecified.
            var position = CameraPosition.worldFacing
            if let positionJson = jsonObject[DefaultFrameSourceHandler.positionKey] as? String {
                SDCCameraPositionFromJSONString(positionJson, &position)
            }
            let lensPosition = (jsonObject[DefaultFrameSourceHandler.lensPositionKey] as? Double) ?? 1
            frameSource = SequenceFrameSource(
                captureDevicePosition: position.captureDevicePosition,
                lensPosition: CGFloat(lensPosition)
            )
            sequenceFrameSource = frameSource
            sequenceFrameSourceId = id
        }
        // The sequence source is (about to be) the context's active source — drop any other
        // tracked source on the reuse path too, or a native re-target that set `camera` would
        // keep winning in switchCameraToState.
        camera = nil
        imageFrameSource = nil

        if let desiredStateJson = jsonObject[DefaultFrameSourceHandler.desiredStateKey] as? String {
            var desiredState = FrameSourceState.off
            SDCFrameSourceStateFromJSONString(desiredStateJson, &desiredState)
            frameSource.switch(toDesiredState: desiredState)
        }
        return frameSource
    }

    public func addFrameToSequenceFrameSource(
        frameSourceId: String,
        width: Int,
        height: Int,
        frameData: Data
    ) -> SequenceFrameSourceAddFrameResult {
        guard let frameSource = sequenceFrameSource, frameSourceId == sequenceFrameSourceId else {
            return .noSuchFrameSource
        }
        // Reject undersized buffers upfront; a partially-copied buffer would silently corrupt
        // the frame rather than fail cleanly.
        let expectedSize = width * height * 3 / 2
        guard frameData.count >= expectedSize else {
            return .invalidFrameData
        }
        guard
            let sampleBuffer = Self.makeSampleBuffer(
                width: width,
                height: height,
                frameData: frameData,
                presentationTimeStampValue: nextPresentationTimeStampValue
            )
        else {
            return .invalidFrameData
        }
        nextPresentationTimeStampValue += 1
        frameSource.add(sampleBuffer)
        return .added
    }

    public func getSequenceFrameSourceState(frameSourceId: String) -> FrameSourceState? {
        guard let frameSource = sequenceFrameSource, frameSourceId == sequenceFrameSourceId else {
            return nil
        }
        return frameSource.currentState
    }

    private func clearSequenceFrameSource() {
        sequenceFrameSource = nil
        sequenceFrameSourceId = nil
    }

    /// Builds a biplanar (`420YpCbCr8BiPlanarFullRange`) CVPixelBuffer from the NV21 bytes —
    /// Y plane (`width*height`) followed by the interleaved chroma plane — wraps it in a ready
    /// CMSampleBuffer suitable for SequenceFrameSource.add(_:). The scanner consumes the luma
    /// plane, so the NV21-vs-NV12 chroma ordering difference does not affect recognition.
    private static func makeSampleBuffer(
        width: Int,
        height: Int,
        frameData: Data,
        presentationTimeStampValue: Int64
    ) -> CMSampleBuffer? {
        var pixelBufferOut: CVPixelBuffer?
        let createStatus = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            nil,
            &pixelBufferOut
        )
        guard createStatus == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        frameData.withUnsafeBytes { (source: UnsafeRawBufferPointer) in
            guard let sourceBase = source.baseAddress else { return }
            var sourceOffset = 0
            for plane in 0..<2 {
                guard let destinationBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane) else {
                    continue
                }
                let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
                let planeHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
                for row in 0..<planeHeight {
                    if sourceOffset + width <= frameData.count {
                        memcpy(destinationBase + row * bytesPerRow, sourceBase + sourceOffset, width)
                    }
                    sourceOffset += width
                }
            }
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        var formatDescriptionOut: CMVideoFormatDescription?
        let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescriptionOut
        )
        guard formatStatus == noErr, let formatDescription = formatDescriptionOut else {
            return nil
        }

        // A valid, monotonically increasing presentation timestamp is required; duration and
        // decode timestamp can stay invalid.
        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMTime(value: presentationTimeStampValue, timescale: 30),
            decodeTimeStamp: .invalid
        )
        var sampleBufferOut: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBufferOut
        )
        guard sampleStatus == noErr else {
            return nil
        }
        return sampleBufferOut
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

    private func checkAndSetZoomListener(camera: Camera, json: JSONValue) {
        if json.containsKey(DefaultFrameSourceHandler.hasZoomListenersKey) {
            if json.bool(forKey: DefaultFrameSourceHandler.hasZoomListenersKey) {
                camera.addZoomListener(zoomListener)
            } else {
                camera.removeZoomListener(zoomListener)
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
        if self.camera == nil && self.imageFrameSource == nil && self.sequenceFrameSource == nil {
            whenDone?(true)
            return
        }

        if let camera = camera {
            camera.switch(toDesiredState: newState, completionHandler: whenDone)
        } else if let imageFrameSource = imageFrameSource {
            imageFrameSource.switch(toDesiredState: newState, completionHandler: whenDone)
        } else if let sequenceFrameSource = sequenceFrameSource {
            // The native SequenceFrameSource switchToDesiredState has no completion callback;
            // the state flips synchronously, so report success to mirror the common contract.
            sequenceFrameSource.switch(toDesiredState: newState)
            whenDone?(true)
        }
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
        let cameraId = self.camera.map { ObjectIdentifier($0) }
        NSLog("[SDC32484] DefaultFrameSourceHandler.releaseCamera: entry camera=\(String(describing: cameraId))")
        camera?.switch(toDesiredState: .off)
        camera = nil
        imageFrameSource = nil
        clearSequenceFrameSource()
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

    public func addZoomListener() {
        camera?.addZoomListener(zoomListener)
    }

    public func removeZoomListener() {
        camera?.removeZoomListener(zoomListener)
    }

    // MARK: - Private Constants

    private static let desiredTorchStateKey = "desiredTorchState"
    private static let idKey = "id"
    private static let positionKey = "position"
    private static let lensPositionKey = "lensPosition"
    private static let desiredStateKey = "desiredState"
    private static let hasTorchStateListenersKey = "hasTorchStateListeners"
    private static let hasMacroModeListenersKey = "hasMacroModeListeners"
    private static let hasZoomListenersKey = "hasZoomListeners"
}

private extension CameraPosition {
    var captureDevicePosition: AVCaptureDevice.Position {
        switch self {
        case .userFacing:
            return .front
        case .worldFacing:
            return .back
        default:
            return .unspecified
        }
    }
}
