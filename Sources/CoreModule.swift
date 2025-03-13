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
        }
    }
}

open class CoreModule: NSObject, FrameworkModule {
    private let frameSourceDeserializer: FrameworksFrameSourceDeserializer
    private let frameSourceListener: FrameworksFrameSourceListener
    private let dataCaptureContextListener: FrameworksDataCaptureContextListener
    private let dataCaptureViewListener: FrameworksDataCaptureViewListener
    private let contextLock = DispatchSemaphore(value: 1)

    public init(frameSourceDeserializer: FrameworksFrameSourceDeserializer,
                frameSourceListener: FrameworksFrameSourceListener,
                dataCaptureContextListener: FrameworksDataCaptureContextListener,
                dataCaptureViewListener: FrameworksDataCaptureViewListener) {
        self.frameSourceDeserializer = frameSourceDeserializer
        self.frameSourceListener = frameSourceListener
        self.dataCaptureContextListener = dataCaptureContextListener
        self.dataCaptureViewListener = dataCaptureViewListener
    }

    var dataCaptureContext: DataCaptureContext? {
        willSet {
            dataCaptureContext?.removeListener(dataCaptureContextListener)
        }
        didSet {
            dataCaptureContext?.addListener(dataCaptureContextListener)
            if let dataCaptureContext = dataCaptureContext {
                DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureContextDeserialized(context: dataCaptureContext)
            }
        }
    }

    var dataCaptureView: DataCaptureView? {
        return DataCaptureViewHandler.shared.topmostDataCaptureView
    }


    private lazy var deserializers: Deserializers = {
        Deserializers.Factory.create(frameSourceDeserializerDelegate: frameSourceDeserializer)
    }()

    public let defaults: DefaultsEncodable = CoreDefaults.shared

    public func createContextFromJSON(_ json: String, result: FrameworksResult) {
        if (dataCaptureContext != nil) {
            disposeContext()
        }

        do {
            contextLock.wait()
            defer { contextLock.signal() }

            let deserializerResult = try deserializers.dataCaptureContextDeserializer.context(fromJSONString: json)
            dataCaptureContext = deserializerResult.context
            
            LastFrameData.shared.configure(configuration: FramesHandlingConfiguration.create(contextCreationJson: json))
            
            result.success()
        } catch {
            Log.error("Error occurred: \n")
            Log.error(error)
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
        }
    }

    public func updateContextFromJSON(_ json: String, result: FrameworksResult) {
        guard let dataCaptureContext = dataCaptureContext else {
            createContextFromJSON(json, result: result)
            return
        }
        
        do {
            contextLock.wait()
            defer { contextLock.signal() }
            
            let _ = try deserializers.dataCaptureContextDeserializer.update(dataCaptureContext,
                                                                            view: nil,
                                                                            components: [],
                                                                            fromJSON: json)
            
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

    public func viewPointForFramePoint(json: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let dataCaptureView = self.dataCaptureView else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }
            guard let point = CGPoint(json: json) else {
                Log.error(ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                return
            }
            let viewPoint = dataCaptureView.viewPoint(forFramePoint: point)
            result.success(result: viewPoint.jsonString)
        }
        dispatchMain(block)
    }

    public func viewQuadrilateralForFrameQuadrilateral(json: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let dataCaptureView = self.dataCaptureView else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }
            var quadrilateral = Quadrilateral()
            guard SDCQuadrilateralFromJSONString(json, &quadrilateral) else {
                Log.error(ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                return
            }
            let viewQuad = dataCaptureView.viewQuadrilateral(forFrameQuadrilateral: quadrilateral)
            result.success(result: viewQuad.jsonString)
        }
        dispatchMain(block)
    }

    public func getCameraState(cameraPosition: String, result: FrameworksResult) {
        var position = CameraPosition.unspecified
        SDCCameraPositionFromJSONString(cameraPosition, &position)
        guard let camera = frameSourceDeserializer.camera, camera.position == position else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        result.success(result: camera.position.jsonString)
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
        dataCaptureContext?.dispose()
        dataCaptureContext = nil
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

    public func registerDataCaptureViewListener() {
        dataCaptureViewListener.enable()
    }

    public func unregisterDataCaptureViewListener() {
        dataCaptureViewListener.disable()
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
        dataCaptureContext?.removeAllModes()
        DeserializationLifeCycleDispatcher.shared.dispatchAllModesRemovedFromContext()
        result.success(result: nil)
    }
    
    public func createDataCaptureView(viewJson: String, result: FrameworksResult) -> DataCaptureView? {
        guard let dcContext = dataCaptureContext else {
            result.reject(error: ScanditFrameworksCoreError.nilDataCaptureContext)
            return nil
        }
        
        let overlays = getOverlaysFromViewJson(viewJson)
        // remove the overlays key so that the native sdk will not handle them
        guard let dataCaptureViewJson = removeJsonKey(from: viewJson, key: "overlays") else {
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: nil, json: viewJson))
            return nil
        }
        
        return dispatchMainSync { () -> DataCaptureView? in
            do {
                let view = try deserializers.dataCaptureViewDeserializer.view(fromJSONString: dataCaptureViewJson, with: dcContext)
                onViewDeserialized(view)
                
                // add overlays
                for overlay in overlays {
                    // Add new overlays
                    try DeserializationLifeCycleDispatcher.shared.dispatchAddOverlayToView(view: view, overlayJson: overlay)
                }
                result.success(result: nil)
                return view
            } catch {
                result.reject(error: error)
                return nil
            }
        }
    }

    public func updateDataCaptureView(viewJson: String, result: FrameworksResult) {
        guard let view = dataCaptureView else {
            // if the view was not created yet, when it will be created it will just be the updated one
            result.success()
            return
        }
        
        let overlays = getOverlaysFromViewJson(viewJson)
        // remove the overlays key so that the native sdk will not handle them
        guard let dataCaptureViewJson = removeJsonKey(from: viewJson, key: "overlays") else {
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: nil, json: viewJson))
            return
        }
        
        // update view
        dispatchMainSync {
            do {
                try deserializers.dataCaptureViewDeserializer.update(view, fromJSONString: dataCaptureViewJson)
            } catch {
                result.reject(error: error)
                return
            }
        }
        
        // remove existing overlays
        DataCaptureViewHandler.shared.removeAllOverlaysFromView(view)
        
        // add overlays
        do {
            for overlay in overlays {
                // Add new overlays
                try DeserializationLifeCycleDispatcher.shared.dispatchAddOverlayToView(view: view, overlayJson: overlay)
            }
            result.success(result: nil)
        } catch  {
            result.reject(error: error)
        }
    }
    
    private func getOverlaysFromViewJson(_ viewJson: String) -> [String] {
        var overlays = [String]()

        if let data = viewJson.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            
            if let overlaysJson = json["overlays"] as? [[String: Any]] {
                for overlay in overlaysJson {
                    if let overlayData = try? JSONSerialization.data(withJSONObject: overlay, options: []),
                       let overlayString = String(data: overlayData, encoding: .utf8) {
                        overlays.append(overlayString)
                    }
                }
            }
        }

        return overlays
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
        dataCaptureView.removeListener(dataCaptureViewListener)
        if let _ = DataCaptureViewHandler.shared.removeView(dataCaptureView) {
            dispatchMain {
                dataCaptureView.removeFromSuperview()
            }
        }
    }
    
    public func disposeDataCaptureView() {
        removeTopMostDataCaptureView()
    }

    private func removeTopMostDataCaptureView() {
        if let view = DataCaptureViewHandler.shared.removeTopmostView() {
            dispatchMain {
                view.removeFromSuperview()
            }
            view.removeListener(dataCaptureViewListener)
        }
    }

    private func onViewDeserialized(_ dataCaptureView: DataCaptureView) {
        dataCaptureView.addListener(dataCaptureViewListener)
        DataCaptureViewHandler.shared.addView(dataCaptureView)
        DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureViewDeserialized(view: dataCaptureView)
    }

    private func removeAllViews() {
        for view in DataCaptureViewHandler.shared.removeAllViews() {
            view.removeListener(dataCaptureViewListener)
        }
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
        view.removeListener(dataCaptureViewListener)
        _ = DataCaptureViewHandler.shared.removeView(view)
        // dispatch that the view has been removed
        DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureViewDeserialized(view: nil)
    }
}
