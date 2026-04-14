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
                message = "Unable to deserialize the following JSON:\n\(json ?? "null")"
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

open class CoreModule: BaseFrameworkModule {
    private let emitter: Emitter
    private let frameSourceDeserializer: FrameworksFrameSourceDeserializer
    private let frameSourceListener: FrameworksFrameSourceListener
    private let dataCaptureContextListener: FrameworksDataCaptureContextListener
    private let contextLock = DispatchSemaphore(value: 1)
    private let captureContext = DefaultFrameworksCaptureContext.shared
    private let frameSourceHandler: FrameSourceHandler

    public init(
        emitter: Emitter,
        frameSourceDeserializer: FrameworksFrameSourceDeserializer,
        frameSourceListener: FrameworksFrameSourceListener,
        dataCaptureContextListener: FrameworksDataCaptureContextListener,
        frameSourceHandler: FrameSourceHandler
    ) {
        self.emitter = emitter
        self.frameSourceDeserializer = frameSourceDeserializer
        self.frameSourceListener = frameSourceListener
        self.dataCaptureContextListener = dataCaptureContextListener
        self.frameSourceHandler = frameSourceHandler
    }

    public static func create(emitter: Emitter) -> CoreModule {
        let frameSourceListener = FrameworksFrameSourceListener(eventEmitter: emitter)
        let torchStateListener = FrameworksTorchListener(eventEmitter: emitter)
        let macroModeListener = FrameworksMacroModeListener(eventEmitter: emitter)
        let frameSourceHandler = DefaultFrameSourceHandler(
            frameSourceListener: frameSourceListener,
            torchStateListener: torchStateListener,
            macroModeListener: macroModeListener
        )
        let frameSourceDeserializer = FrameworksFrameSourceDeserializer(frameSourceHandler: frameSourceHandler)

        return CoreModule(
            emitter: emitter,
            frameSourceDeserializer: frameSourceDeserializer,
            frameSourceListener: frameSourceListener,
            dataCaptureContextListener: FrameworksDataCaptureContextListener(eventEmitter: emitter),
            frameSourceHandler: frameSourceHandler
        )
    }

    public override func getDefaults() -> [String: Any?] {
        CoreDefaults.shared.toEncodable()
    }

    public func createContextFromJson(contextJson: String, result: FrameworksResult) {
        do {
            self.contextLock.wait()
            defer { self.contextLock.signal() }

            let _ = try captureContext.initialize(
                json: contextJson,
                frameSourceListener: frameSourceListener,
                frameSourceDeserializerListener: frameSourceDeserializer,
                dataCaptureContextListener: dataCaptureContextListener
            )

            LastFrameData.shared.configure(
                configuration: FramesHandlingConfiguration.create(contextCreationJson: contextJson)
            )

            result.success()
        } catch {
            Log.error("Error occurred: \n")
            Log.error(error)
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
        }
    }

    public func updateContextFromJson(contextJson: String, result: FrameworksResult) {
        do {
            self.contextLock.wait()
            defer { self.contextLock.signal() }

            try captureContext.update(json: contextJson)

            LastFrameData.shared.configure(
                configuration: FramesHandlingConfiguration.create(contextCreationJson: contextJson)
            )

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

    public func emitFeedback(feedbackJson: String, result: FrameworksResult) {
        do {
            let feedback = try Feedback(fromJSONString: feedbackJson)
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

    public func viewPointForFramePoint(viewId: Int, pointJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard self != nil else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let frameworksDataCaptureView = DataCaptureViewHandler.shared.getView(viewId) else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }

            let viewPoint = frameworksDataCaptureView.mapFramePointToView(jsonString: pointJson)
            result.success(result: viewPoint?.jsonString)
        }
        dispatchMain(block)
    }

    public func viewQuadrilateralForFrameQuadrilateral(viewId: Int, quadrilateralJson: String, result: FrameworksResult)
    {
        let block = { [weak self] in
            guard self != nil else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let frameworksDataCaptureView = DataCaptureViewHandler.shared.getView(viewId) else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }
            let viewQuad = frameworksDataCaptureView.mapFrameQuadrilateralToView(jsonString: quadrilateralJson)
            result.success(result: viewQuad?.jsonString)
        }
        dispatchMain(block)
    }

    public func getCurrentCameraState(result: FrameworksResult) {
        guard let cameraState = frameSourceHandler.currentCameraState else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        result.success(result: cameraState.jsonString)
    }

    public func getCameraState(cameraPosition: String, result: FrameworksResult) {
        guard let cameraState = frameSourceHandler.getCameraStateByPosition(cameraPosition: cameraPosition) else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        result.success(result: cameraState.jsonString)
    }

    public func isTorchAvailable(cameraPosition: String, result: FrameworksResult) {
        guard let isTorchAvailable = frameSourceHandler.getIsTorchAvailableByPosition(cameraPosition: cameraPosition)
        else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }

        result.success(result: isTorchAvailable)
    }

    public func isMacroModeAvailable(result: FrameworksResult) {
        result.success(result: Camera.isMacroModeAvailable)
    }

    public func disposeContext(result: FrameworksResult) {
        self.contextLock.wait()
        defer { self.contextLock.signal() }

        removeAllViews()
        captureContext.release(dataCaptureContextListener: dataCaptureContextListener)
        frameSourceHandler.releaseCamera()
        LastFrameData.shared.release()
        DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureContextDisposed()
        result.success()
    }

    public override func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public override func didStop() {
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
        Deserializers.Factory.clearDeserializers()
        super.didStop()
        disposeContext(result: NoopFrameworksResult())
    }

    public func subscribeContextListener(result: FrameworksResult) {
        dataCaptureContextListener.enable()
        result.success()
    }

    public func unsubscribeContextListener(result: FrameworksResult) {
        dataCaptureContextListener.disable()
        result.success()
    }

    public func registerListenerForViewEvents(viewId: Int, result: FrameworksResult) {
        if let frameworksView = DataCaptureViewHandler.shared.getView(viewId) {
            frameworksView.registerDataCaptureViewListener()
        }
        result.success()
    }

    public func unregisterListenerForViewEvents(viewId: Int, result: FrameworksResult) {
        if let frameworksView = DataCaptureViewHandler.shared.getView(viewId) {
            frameworksView.unregisterDataCaptureViewListener()
        }
        result.success()
    }

    public func unregisterTopmostDataCaptureViewListener() {
        if let frameworksView = DataCaptureViewHandler.shared.topmostDataCaptureView {
            frameworksView.unregisterDataCaptureViewListener()
        }
    }

    public func registerFocusGestureListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = DataCaptureViewHandler.shared.getView(viewId) else {
            addPostSpecificViewCreationAction(viewId: viewId) { [weak self] in
                self?.registerFocusGestureListener(viewId: viewId, result: result)
            }
            return
        }
        let focusGestureListener = FrameworksFocusGestureListener(eventEmitter: emitter, viewId: viewId)
        viewInstance.registerFocusGestureListener(focusGestureListener)
        result.successAndKeepCallback(result: nil)
    }

    public func unregisterFocusGestureListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = DataCaptureViewHandler.shared.getView(viewId) else {
            result.success()
            return
        }
        viewInstance.unregisterFocusGestureListener()
        result.success(result: nil)
    }

    public func registerZoomGestureListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = DataCaptureViewHandler.shared.getView(viewId) else {
            addPostSpecificViewCreationAction(viewId: viewId) { [weak self] in
                self?.registerZoomGestureListener(viewId: viewId, result: result)
            }
            return
        }
        let zoomGestureListener = FrameworksZoomGestureListener(eventEmitter: emitter, viewId: viewId)
        viewInstance.registerZoomGestureListener(zoomGestureListener)
        result.successAndKeepCallback(result: nil)
    }

    public func unregisterZoomGestureListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = DataCaptureViewHandler.shared.getView(viewId) else {
            result.success()
            return
        }
        viewInstance.unregisterZoomGestureListener()
        result.success(result: nil)
    }

    public func triggerFocus(viewId: Int, pointJson: String, result: FrameworksResult) {
        guard let viewInstance = DataCaptureViewHandler.shared.getView(viewId) else {
            addPostSpecificViewCreationAction(viewId: viewId) { [weak self] in
                self?.triggerFocus(viewId: viewId, pointJson: pointJson, result: result)
            }
            return
        }
        viewInstance.triggerFocus(pointJson: pointJson)
        result.success(result: nil)
    }

    public func triggerZoomIn(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = DataCaptureViewHandler.shared.getView(viewId) else {
            addPostSpecificViewCreationAction(viewId: viewId) { [weak self] in
                self?.triggerZoomIn(viewId: viewId, result: result)
            }
            return
        }
        viewInstance.triggerZoomIn()
        result.success(result: nil)
    }

    public func triggerZoomOut(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = DataCaptureViewHandler.shared.getView(viewId) else {
            addPostSpecificViewCreationAction(viewId: viewId) { [weak self] in
                self?.triggerZoomOut(viewId: viewId, result: result)
            }
            return
        }
        viewInstance.triggerZoomOut()
        result.success(result: nil)
    }

    public func registerFrameSourceListener(result: FrameworksResult) {
        frameSourceListener.enable()
        result.successAndKeepCallback(result: nil)
    }

    public func unregisterFrameSourceListener(result: FrameworksResult) {
        frameSourceListener.disable()
        result.success(result: nil)
    }

    public func registerTorchStateListener(result: FrameworksResult) {
        frameSourceHandler.addTorchStateListener()
        result.successAndKeepCallback(result: nil)
    }

    public func unregisterTorchStateListener(result: FrameworksResult) {
        frameSourceHandler.removeTorchStateListener()
        result.success(result: nil)
    }

    public func registerMacroModeListener(result: FrameworksResult) {
        frameSourceHandler.addMacroModeListener()
        result.successAndKeepCallback(result: nil)
    }

    public func unregisterMacroModeListener(result: FrameworksResult) {
        frameSourceHandler.removeMacroModeListener()
        result.success(result: nil)
    }

    public func switchCameraToDesiredState(stateJson: String, result: FrameworksResult) {
        var state = FrameSourceState.off
        SDCFrameSourceStateFromJSONString(stateJson, &state)
        frameSourceHandler.switchCameraToState(newState: state) { success in
            if success {
                result.success(result: nil)
            } else {
                result.reject(code: "-1", message: "Unable to switch the camera to \(stateJson).", details: nil)
            }
        }
    }

    public func addModeToContext(modeJson: String, result: FrameworksResult) {
        do {
            try DeserializationLifeCycleDispatcher.shared.dispatchAddModeToContext(modeJson: modeJson)
            result.success(result: nil)
        } catch {
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
        LastFrameData.shared.release()
        result.success(result: nil)
    }

    public func createDataCaptureView(
        viewJson: String,
        result: FrameworksResult,
        viewId: Int = 0,
        completion: ((DataCaptureView?) -> Void)? = nil
    ) {
        guard let dcContext = captureContext.context else {
            result.reject(error: ScanditFrameworksCoreError.nilDataCaptureContext)
            completion?(nil)
            return
        }

        let creationData = DataCaptureViewCreationData.fromJson(viewJson)

        if let existingview = DataCaptureViewHandler.shared.getView(creationData.viewId) {
            result.success(result: nil)
            completion?(existingview.view)
            return
        }

        dispatchMain { [weak self] in
            guard let self = self else {
                completion?(nil)
                return
            }

            do {

                let frameworksView = try FrameworksDataCaptureView.create(
                    emitter: self.emitter,
                    dataCaptureContext: dcContext,
                    creationData: creationData
                )

                DataCaptureViewHandler.shared.addView(frameworksView)
                DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureViewDeserialized(view: frameworksView.view)

                // Handle overlays
                for entry in creationData.overlays {
                    frameworksView.setPendingOverlayKey(entry.key)
                    try DeserializationLifeCycleDispatcher.shared.dispatchAddOverlayToView(
                        view: frameworksView,
                        overlayJson: entry.jsonString
                    )
                }

                // Execute post view creation actions
                for action in self.getPostSpecificViewCreationActions(viewId: frameworksView.viewId) {
                    action()
                }

                result.success(result: nil)
                completion?(frameworksView.view)
            } catch {
                result.reject(error: error)
                completion?(nil)
            }
        }
    }

    public func updateDataCaptureView(viewJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard self != nil else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }

            let updateData = DataCaptureViewCreationData.fromJson(viewJson)

            guard let frameworksView = DataCaptureViewHandler.shared.getView(updateData.viewId) else {
                Log.info(
                    "updateDataCaptureView: no view found for viewId \(updateData.viewId). "
                        + "The view may not have been created yet or was already disposed."
                )
                result.success()
                return
            }
            do {

                try frameworksView.updateView(updateData: updateData)

                // Diff overlays: only add/remove what changed
                let incomingKeys = Set(updateData.overlays.map(\.key))
                let existingKeys = frameworksView.overlayKeys

                for key in existingKeys.subtracting(incomingKeys) {
                    frameworksView.removeOverlayByKey(key)
                }

                let keysToAdd = incomingKeys.subtracting(existingKeys)
                for entry in updateData.overlays where keysToAdd.contains(entry.key) {
                    // Remove any existing overlay of the same type but different modeId
                    frameworksView.removeExistingOverlaysOfType(entry.type, excludingKey: entry.key)
                    frameworksView.setPendingOverlayKey(entry.key)
                    try DeserializationLifeCycleDispatcher.shared.dispatchAddOverlayToView(
                        view: frameworksView,
                        overlayJson: entry.jsonString
                    )
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
            let updatedJsonString = String(data: updatedData, encoding: .utf8)
        else {
            return nil
        }

        return updatedJsonString
    }

    public func dataCaptureViewDisposed(_ dataCaptureView: DataCaptureView) {
        clearPostSpecificViewCreationActions(viewId: dataCaptureView.tag)
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
        dispatchMain {
            DataCaptureViewHandler.shared.removeAllViews()
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

    public func getLastFrameOrNullAsJson(frameId: String, result: FrameworksResult) {
        LastFrameData.shared.getLastFrameDataJSON(frameId: frameId) {
            result.success(result: $0)
        }
    }

    public func getLastFrameOrNullAsMap(frameId: String, result: FrameworksResult) {
        LastFrameData.shared.getLastFrameDataBytes(frameId: frameId) {
            result.success(result: $0)
        }
    }

    public override func createCommand(_ method: any FrameworksMethodCall) -> (any BaseCommand)? {
        CoreModuleCommandFactory.create(module: self, method)
    }

    /// Single dispatcher for all Core commands.
    /// Creates command from method call and executes it.
    /// - Parameter method: The method call containing method name and parameters
    /// - Parameter result: The result handler for async responses
    /// - Returns: true if the method was handled, false if unknown
    public func execute(
        _ method: FrameworksMethodCall,
        result: FrameworksResult,
        module: FrameworkModule
    ) -> Bool {
        guard let command = module.createCommand(method) else {
            return false
        }
        command.execute(result: result)
        return true
    }
}

extension CoreModule: DeserializationLifeCycleObserver {
    public func dataCaptureView(removed view: DataCaptureView) {
        clearPostSpecificViewCreationActions(viewId: view.tag)
        dispatchMain {
            DataCaptureViewHandler.shared.removeView(view.tag)
            DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureViewDeserialized(view: nil)
        }
    }
}
