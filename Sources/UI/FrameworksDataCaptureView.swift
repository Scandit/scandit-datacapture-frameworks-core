/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

@objc
public class FrameworksDataCaptureView: NSObject, FrameworksBaseView {
    private var internalViewId: Int = 0
    private var internalParentId: Int? = nil

    private var viewOverlays: [DataCaptureOverlay] = []
    private var overlayKeyMap: [String: DataCaptureOverlay] = [:]
    private var pendingOverlayKey: String?

    private var viewListener: FrameworksDataCaptureViewListener?
    private var focusGestureListener: FrameworksFocusGestureListener?
    private var zoomGestureListener: FrameworksZoomGestureListener?

    public var view: DataCaptureView?

    public var viewId: Int {
        internalViewId
    }

    public var parentId: Int? {
        internalParentId
    }

    public var overlays: [DataCaptureOverlay] {
        viewOverlays
    }

    var overlayKeys: Set<String> { Set(overlayKeyMap.keys) }

    func setPendingOverlayKey(_ key: String) {
        pendingOverlayKey = key
    }

    func removeOverlayByKey(_ key: String) {
        guard let overlay = overlayKeyMap.removeValue(forKey: key) else { return }
        removeOverlay(overlay)
    }

    func removeExistingOverlaysOfType(_ type: String, excludingKey key: String) {
        let conflictingKeys = overlayKeyMap.keys.filter { existingKey in
            existingKey != key && existingKey.hasPrefix("\(type):")
        }
        for conflictingKey in conflictingKeys {
            removeOverlayByKey(conflictingKey)
        }
    }

    private let emitter: Emitter
    private let viewDeserializer: DataCaptureViewDeserializer

    private init(emitter: Emitter, viewDeserializer: DataCaptureViewDeserializer) {
        self.emitter = emitter
        self.viewDeserializer = viewDeserializer
    }

    public func addOverlay(_ overlay: DataCaptureOverlay) {
        viewOverlays.append(overlay)
        if let key = pendingOverlayKey {
            overlayKeyMap[key] = overlay
            pendingOverlayKey = nil
        }
        dispatchMain { [weak self] in
            guard let self else { return }
            self.view?.addOverlay(overlay)
        }
    }

    public func removeOverlay(_ overlay: DataCaptureOverlay) {
        if let index = viewOverlays.firstIndex(where: { $0 === overlay }) {
            viewOverlays.remove(at: index)
            dispatchMain { [weak self] in
                guard let self else { return }
                self.view?.removeOverlay(overlay)
                DeserializationLifeCycleDispatcher.shared.dispatchOverlayRemoved(overlay: overlay)
            }
        }
    }

    public func removeAllOverlays() {
        let overlaysCopy = overlays
        for overlay in overlaysCopy {
            removeOverlay(overlay)
        }
        overlayKeyMap.removeAll()
    }

    public func dispose() {
        dispatchMain { [weak self] in
            guard let self else { return }
            self.removeAllOverlays()
            self.overlayKeyMap.removeAll()
            if let viewListener = self.viewListener {
                self.view?.removeListener(viewListener)
            }
            if let focusGestureListener = focusGestureListener {
                view?.focusGesture?.remove(focusGestureListener)
            }
            focusGestureListener = nil
            if let zoomGestureListener = zoomGestureListener {
                self.view?.zoomGesture?.remove(zoomGestureListener)
            }
            zoomGestureListener = nil
            self.viewListener = nil
            self.view?.removeFromSuperview()
            self.view = nil
        }
    }

    private func deserializeView(
        dataCaptureContext: DataCaptureContext,
        creationData: DataCaptureViewCreationData
    ) throws {
        internalViewId = creationData.viewId
        internalParentId = creationData.parentId

        view = try viewDeserializer.view(fromJSONString: creationData.viewJson, with: dataCaptureContext)

        // Set the ID tag to be able to find a view with a specific tag
        view?.tag = viewId

        // Initialize and set view listener
        viewListener = FrameworksDataCaptureViewListener(eventEmitter: emitter, viewId: viewId)
        if let viewListener = viewListener {
            view?.addListener(viewListener)
            // Enable view listener by default
            viewListener.enable()
        }
    }

    public func updateView(updateData: DataCaptureViewCreationData) throws {
        if let currentView = view {
            try viewDeserializer.update(currentView, fromJSONString: updateData.viewJson)
        }
    }

    public func mapFramePointToView(jsonString: String) -> CGPoint? {
        guard let point = CGPoint(json: jsonString) else {
            return nil
        }
        return self.view?.viewPoint(forFramePoint: point)
    }

    public func mapFrameQuadrilateralToView(jsonString: String) -> Quadrilateral? {
        var quadrilateral = Quadrilateral()
        guard SDCQuadrilateralFromJSONString(jsonString, &quadrilateral) else {
            Log.error(ScanditFrameworksCoreError.deserializationError(error: nil, json: jsonString))
            return nil
        }
        return self.view?.viewQuadrilateral(forFrameQuadrilateral: quadrilateral)
    }

    public func registerDataCaptureViewListener() {
        viewListener?.enable()
    }

    public func unregisterDataCaptureViewListener() {
        viewListener?.disable()
    }

    public func registerFocusGestureListener(_ listener: FrameworksFocusGestureListener) {
        focusGestureListener = listener
        DispatchQueue.main.async {
            self.view?.focusGesture?.add(listener)
        }
    }

    public func unregisterFocusGestureListener() {
        if let focusGestureListener = focusGestureListener {
            DispatchQueue.main.async {
                self.view?.focusGesture?.remove(focusGestureListener)
            }
        }
        focusGestureListener = nil
    }

    public func registerZoomGestureListener(_ listener: FrameworksZoomGestureListener) {
        zoomGestureListener = listener
        DispatchQueue.main.async {
            self.view?.zoomGesture?.add(listener)
        }
    }

    public func unregisterZoomGestureListener() {
        if let zoomGestureListener = zoomGestureListener {
            DispatchQueue.main.async {
                self.view?.zoomGesture?.remove(zoomGestureListener)
            }
        }
        zoomGestureListener = nil
    }

    public func findFirstOfType<T: DataCaptureOverlay>() -> T? {
        overlays.first { $0 is T } as? T
    }

    public func triggerFocus(pointJson: String) {
        var point = PointWithUnit.zero
        guard SDCPointWithUnitFromJSONString(pointJson, &point) else {
            return
        }
        DispatchQueue.main.async {
            self.view?.focusGesture?.triggerFocus(point)
        }
    }

    public func triggerZoomIn() {
        DispatchQueue.main.async {
            self.view?.zoomGesture?.triggerZoomIn()
        }
    }

    public func triggerZoomOut() {
        DispatchQueue.main.async {
            self.view?.zoomGesture?.triggerZoomOut()
        }
    }

    // MARK: - Factory method

    public static func create(
        emitter: Emitter,
        dataCaptureContext: DataCaptureContext,
        creationData: DataCaptureViewCreationData
    ) throws -> FrameworksDataCaptureView {
        let view = FrameworksDataCaptureView(
            emitter: emitter,
            viewDeserializer: DataCaptureViewDeserializer(modeDeserializers: [])
        )
        try view.deserializeView(dataCaptureContext: dataCaptureContext, creationData: creationData)
        return view
    }
}
