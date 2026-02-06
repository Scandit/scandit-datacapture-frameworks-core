/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public class FrameworksDataCaptureView: FrameworksBaseView {
    private var _viewId: Int = 0

    private var viewOverlays = [DataCaptureOverlay]()

    private var viewListener: FrameworksDataCaptureViewListener?

    public var view: DataCaptureView?

    public var viewId: Int {
        return _viewId
    }

    public var overlays: [DataCaptureOverlay] {
        return viewOverlays
    }

    private let emitter: Emitter
    private let viewDeserializer: DataCaptureViewDeserializer

    private init(emitter: Emitter, viewDeserializer: DataCaptureViewDeserializer) {
        self.emitter = emitter
        self.viewDeserializer = viewDeserializer
    }

    public func addOverlay(_ overlay: DataCaptureOverlay) {
        viewOverlays.append(overlay)
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
            }
        }
    }

    public func removeAllOverlays() {
        let overlaysCopy = overlays
        for overlay in overlaysCopy {
            removeOverlay(overlay)
        }
    }

    public func dispose() {
        dispatchMain { [weak self] in
            guard let self else { return }
            self.removeAllOverlays()
            if let viewListener = self.viewListener {
                self.view?.removeListener(viewListener)
            }
            self.viewListener = nil
            self.view?.removeFromSuperview()
            self.view = nil
        }
    }

    private func deserializeView(dataCaptureContext: DataCaptureContext, creationData: DataCaptureViewCreationData) throws {
        _viewId = creationData.viewId

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

    public func findFirstOfType<T: DataCaptureOverlay>() -> T? {
        return overlays.first { $0 is T } as? T
    }

    // MARK: - Factory method

    public static func create(emitter: Emitter,
                             dataCaptureContext: DataCaptureContext,
                             creationData: DataCaptureViewCreationData) throws -> FrameworksDataCaptureView {
        let view = FrameworksDataCaptureView(
            emitter: emitter,
            viewDeserializer: DataCaptureViewDeserializer(modeDeserializers: [])
        )
        try view.deserializeView(dataCaptureContext: dataCaptureContext, creationData: creationData)
        return view
    }
}
