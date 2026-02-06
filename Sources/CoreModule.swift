/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public enum ScanditFrameworksCoreError: Error, CustomNSError {
    case nilDataCaptureView
    case nilDataCaptureContext
    case deserializationError(error: Error?, json: String?)
    case cameraNotReadyError
    case wrongCameraPosition
    case nilSelf
    case nilArgument

    public static var errorDomain: String = "SDCFrameworksErrorDomain"

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }

    public var errorCode: Int {
        switch self {
        case .nilDataCaptureView:
            return 1
        case .nilDataCaptureContext:
            return 2
        case .deserializationError:
            return 3
        case .cameraNotReadyError:
            return 4
        case .wrongCameraPosition:
            return 5
        case .nilSelf:
            return 6
        case .nilArgument:
            return 7
        }
    }

    private var localizedDescription: String {
        switch self {
        case .nilDataCaptureView:
            return "The data capture view is nil."
        case .nilDataCaptureContext:
            return "The data capture context is nil."
        case .deserializationError(let error, let json):
            var message: String
            if let error = error {
                message = "An internal deserialization error happened:\n\(error.localizedDescription)"
            } else {
                message = "Unable to deserialize the following JSON:\n\(json!)"
            }
            return message
        case .cameraNotReadyError:
            return "No camera was deserialized yet or it was disposed."
        case .wrongCameraPosition:
            return "The given camera position doesn't match with the current camera's position."
        case .nilSelf:
            return "The current object got deallocated."
        case .nilArgument:
            return "The argument is nil."
        }
    }
}

open class CoreModule: NSObject, FrameworkModule {
    private let emitter: Emitter
    private let frameSourceDeserializer: FrameworksFrameSourceDeserializer
    private let frameSourceListener: FrameworksFrameSourceListener
    private let dataCaptureContextListener: FrameworksDataCaptureContextListener
    private let contextLock = DispatchSemaphore(value: 1)
    private let captureContext = DefaultFrameworksCaptureContext.shared
    private let viewDeserializer = DataCaptureViewDeserializer(modeDeserializers: [])

    public init(emitter: Emitter,
                frameSourceDeserializer: FrameworksFrameSourceDeserializer,
                frameSourceListener: FrameworksFrameSourceListener,
                dataCaptureContextListener: FrameworksDataCaptureContextListener) {
        self.emitter = emitter
        self.frameSourceDeserializer = frameSourceDeserializer
        self.frameSourceListener = frameSourceListener
        self.dataCaptureContextListener = dataCaptureContextListener
    }
    
    public static func create(emitter: Emitter) -> CoreModule {
        let frameSourceListener = FrameworksFrameSourceListener(eventEmitter: emitter)
        let frameSourceDeserializer = FrameworksFrameSourceDeserializer(frameSourceListener: frameSourceListener,
                                                                        torchListener: frameSourceListener)
        
        return CoreModule (
            emitter: emitter,
            frameSourceDeserializer: frameSourceDeserializer,
            frameSourceListener: frameSourceListener,
            dataCaptureContextListener: FrameworksDataCaptureContextListener(eventEmitter: emitter))
    }

    public let defaults: DefaultsEncodable = CoreDefaults.shared

    public func createContextFromJSON(_ json: String, result: FrameworksResult) {
        do {
            self.contextLock.wait()
            defer { self.contextLock.signal() }
            
            let _ = try captureContext.initialize(
                json: json,
                frameSourceListener: frameSourceListener,
                frameSourceDeserializerListener: frameSourceDeserializer,
                dataCaptureContextListener: dataCaptureContextListener
            )
            
            LastFrameData.shared.configure(configuration: FramesHandlingConfiguration.create(contextCreationJson: json))
            
            result.success()
        } catch {
            Log.error("Error occurred: \n")
            Log.error(error)
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
        }
    }

    public func updateContextFromJSON(_ json: String, result: FrameworksResult) {
        do {
            self.contextLock.wait()
            defer { self.contextLock.signal() }
            
            try captureContext.update(json: json)
            
            LastFrameData.shared.configure(configuration: FramesHandlingConfiguration.create(contextCreationJson: json))
            
            result.success(result: nil)
        } catch {
            Log.error("Error occurred: \n")
            Log.error(error)
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
        }
    }
    
    func jsonStringContainsKey(_ jsonString: String, key: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8) else {
            // Failed to convert the string to data
            return false
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                return json[key] != nil
            }
        } catch {
            // JSON parsing failed
            return false
        }

        return false
    }

    public func emitFeedback(json: String, result: FrameworksResult) {
        do {
            let feedback = try Feedback(fromJSONString: json)
            feedback.emit()

            dispatchMain {
                result.success(result: nil)
            }
        } catch {
            Log.error("Error occurred: \n")
            Log.error(error)
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
        }
    }

    public func viewPointForFramePoint(viewId: Int, json: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let _ = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let frameworksDataCaptureView = DataCaptureViewHandler.shared.getView(viewId) else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }
        
            let viewPoint = frameworksDataCaptureView.mapFramePointToView(jsonString: json)
            result.success(result: viewPoint?.jsonString)
        }
        dispatchMain(block)
    }

    public func viewQuadrilateralForFrameQuadrilateral(viewId: Int, json: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let _ = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let frameworksDataCaptureView = DataCaptureViewHandler.shared.getView(viewId) else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }
            let viewQuad = frameworksDataCaptureView.mapFrameQuadrilateralToView(jsonString: json)
            result.success(result: viewQuad?.jsonString)
        }
        dispatchMain(block)
    }
    
    public func getCurrentCameraState(result: FrameworksResult) {
        guard let camera = frameSourceDeserializer.camera else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        result.success(result: camera.currentState.jsonString)
    }

    public func getCameraState(cameraPosition: String, result: FrameworksResult) {
        var position = CameraPosition.unspecified
        SDCCameraPositionFromJSONString(cameraPosition, &position)
        guard let camera = frameSourceDeserializer.camera, camera.position == position else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        result.success(result: camera.currentState.jsonString)
    }

    public func isTorchAvailable(cameraPosition: String, result: FrameworksResult) {
        guard let camera = frameSourceDeserializer.camera else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        var position = CameraPosition.unspecified
        SDCCameraPositionFromJSONString(cameraPosition, &position)
        guard camera.position == position else {
            Log.error(ScanditFrameworksCoreError.wrongCameraPosition)
            result.reject(error: ScanditFrameworksCoreError.wrongCameraPosition)
            return
        }
        result.success(result: camera.isTorchAvailable)
    }

    public func disposeContext() {
        self.contextLock.wait()
        defer { self.contextLock.signal() }
        
        removeAllViews()
        captureContext.release(dataCaptureContextListener: dataCaptureContextListener)
        frameSourceDeserializer.releaseCurrentCamera()
        LastFrameData.shared.release()
        DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureContextDisposed()
    }

    public func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public func didStop() {
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
        Deserializers.Factory.clearDeserializers()
        disposeContext()
    }

    public func registerDataCaptureContextListener() {
        dataCaptureContextListener.enable()
    }

    public func unregisterDataCaptureContextListener() {
        dataCaptureContextListener.disable()
    }

    public func registerDataCaptureViewListener(viewId: Int) {
        if let frameworksView = DataCaptureViewHandler.shared.getView(viewId) {
            frameworksView.registerDataCaptureViewListener()
        }
    }

    public func unregisterDataCaptureViewListener(viewId: Int) {
        if let frameworksView = DataCaptureViewHandler.shared.getView(viewId) {
            frameworksView.unregisterDataCaptureViewListener()
        }
    }
    
    public func unregisterTopmostDataCaptureViewListener() {
        if let frameworksView = DataCaptureViewHandler.shared.topmostDataCaptureView {
            frameworksView.unregisterDataCaptureViewListener()
        }
    }

    public func registerFrameSourceListener() {
        frameSourceListener.enable()
    }

    public func unregisterFrameSourceListener() {
        frameSourceListener.disable()
    }
    
    public func switchCameraToDesiredState(stateJson: String, result: FrameworksResult) {
        var state = FrameSourceState.off
        SDCFrameSourceStateFromJSONString(stateJson, &state)
        frameSourceDeserializer.switchCameraToState(newState: state) { success in
            if (success) {
                result.success(result: nil)
            } else {
                result.reject(code: "-1", message: "Unable to switch the camera to \(stateJson).", details: nil)
            }
        }
    }
    
    public func addModeToContext(modeJson: String, result: FrameworksResult) {
        do {
            try  DeserializationLifeCycleDispatcher.shared.dispatchAddModeToContext(modeJson: modeJson)
            result.success(result: nil)
        } catch  {
            result.reject(error: error)
        }
    }

    public func removeModeFromContext(modeJson: String, result: FrameworksResult) {
        DeserializationLifeCycleDispatcher.shared.dispatchRemoveModeFromContext(modeJson: modeJson)
        LastFrameData.shared.release()
        result.success(result: nil)
    }

    public func removeAllModes(result: FrameworksResult) {
        captureContext.removeAllModes()
        DeserializationLifeCycleDispatcher.shared.dispatchAllModesRemovedFromContext()
        result.success(result: nil)
    }
    
    public func createDataCaptureView(viewJson: String, result: FrameworksResult, viewId: Int = 0) -> DataCaptureView? {
        guard let dcContext = captureContext.context else {
            result.reject(error: ScanditFrameworksCoreError.nilDataCaptureContext)
            return nil
        }
        
        let creationData = DataCaptureViewCreationData.fromJson(viewJson)
        
        if let existingview = DataCaptureViewHandler.shared.getView(creationData.viewId) {
            result.success(result: nil)
            return existingview.view
        }
        
        return dispatchMainSync { () -> DataCaptureView? in
            do {
                
                let frameworksView = try FrameworksDataCaptureView.create(
                    emitter: self.emitter,
                    dataCaptureContext: dcContext,
                    creationData: creationData
                )
                
                DataCaptureViewHandler.shared.addView(frameworksView)
                DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureViewDeserialized(view: frameworksView.view)
                
                if let createdView = frameworksView.view {
                    // Handle overlays
                    for overlay in creationData.overlaysJson {
                        try DeserializationLifeCycleDispatcher.shared.dispatchAddOverlayToView(
                            view: createdView,
                            overlayJson: overlay
                        )
                    }
                }
                result.success(result: nil)
                return frameworksView.view
            } catch {
                result.reject(error: error)
                return nil
            }
        }
    }

    public func updateDataCaptureView(viewJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let _ = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            
            let updateData = DataCaptureViewCreationData.fromJson(viewJson)
            
            guard let frameworksView = DataCaptureViewHandler.shared.getView(updateData.viewId) else {
                result.success()
                return
            }
            do {
                
                try frameworksView.updateView(updateData: updateData)
                
                
                // Handle overlays
                frameworksView.removeAllOverlays()
                
                if let createdView = frameworksView.view {
                    for overlay in updateData.overlaysJson {
                        try DeserializationLifeCycleDispatcher.shared.dispatchAddOverlayToView(
                            view: createdView,
                            overlayJson: overlay
                        )
                    }
                }
                result.success()
            } catch {
                result.reject(error: error)
            }
        }
        dispatchMain(block)
    }
    
    
    
    private func removeJsonKey(from jsonString: String, key: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        guard var json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        json.removeValue(forKey: key)
        
        guard let updatedData = try? JSONSerialization.data(withJSONObject: json, options: []),
              let updatedJsonString = String(data: updatedData, encoding: .utf8) else {
            return nil
        }
        
        return updatedJsonString
    }

    public func dataCaptureViewDisposed(_ dataCaptureView: DataCaptureView) {
        dispatchMain {
            DataCaptureViewHandler.shared.removeView(dataCaptureView.tag)
        }
    }
    
    public func disposeDataCaptureView() {
        removeTopMostDataCaptureView()
    }

    private func removeTopMostDataCaptureView() {
        dispatchMain {
            _ = DataCaptureViewHandler.shared.removeTopmostView()
        }
    }
    
    private func removeAllViews() {
        DataCaptureViewHandler.shared.removeAllViews()
    }
    
    public func getOpenSourceSoftwareLicenseInfo(result: FrameworksResult) {
        result.success(result: DataCaptureContext.openSourceSoftwareLicenseInfo.licenseText)
    }
    
    public func getLastFrameAsJson(frameId: String, result: FrameworksResult) {
        LastFrameData.shared.getLastFrameDataJSON(frameId: frameId) {
            result.success(result: $0)
        }
    }
}

extension CoreModule: DeserializationLifeCycleObserver {
    public func dataCaptureView(removed view: DataCaptureView) {
        dispatchMain {
            DataCaptureViewHandler.shared.removeView(view.tag)
            // dispatch that the view has been removed
            DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureViewDeserialized(view: nil)
        }
    }
}
