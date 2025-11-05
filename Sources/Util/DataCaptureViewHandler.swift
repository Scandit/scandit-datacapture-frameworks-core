/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation

import ScanditCaptureCore

public final class DataCaptureViewHandler {
    public static let shared = DataCaptureViewHandler()
    private let lock = DispatchSemaphore(value: 1)

    private init() {}

    private var instances = [DataCaptureViewWrapper]()

    var topmostWrapper: DataCaptureViewWrapper? {
        self.lock.wait()
        defer { self.lock.signal() }
        
        return instances.last
    }

    public var topmostDataCaptureView: DataCaptureView? {
        self.lock.wait()
        defer { self.lock.signal() }
        
        return instances.last?.dataCaptureView
    }

    func removeTopmostView() -> DataCaptureView? {
        self.lock.wait()
        defer { self.lock.signal() }

        if let wrapper = topmostWrapper {
            wrapper.dispose()
            instances.removeLast()
            return wrapper.dataCaptureView
        }
        return nil
    }

    func removeView(_ view: DataCaptureView) -> DataCaptureView? {
        self.lock.wait()
        defer { self.lock.signal() }

        if let wrapper = instances.first(where: { $0.dataCaptureView == view }) {
            wrapper.dispose()
            if let index = instances.firstIndex(where: { $0 === wrapper }) {
                instances.remove(at: index)
            }
            return wrapper.dataCaptureView
        }
        return nil
    }

    func addView(_ view: DataCaptureView, withId viewId: Int) {
        self.lock.wait()
        defer { self.lock.signal() }

        instances.append(DataCaptureViewWrapper(dataCaptureView: view, viewId: viewId))
    }
    
    public func getViewById(_ viewId: Int) -> DataCaptureView? {
        self.lock.wait()
        defer { self.lock.signal() }
        
        return instances.first(where: { $0.viewId == viewId })?.dataCaptureView
    }

    func removeAllViews() -> [DataCaptureView] {
        self.lock.wait()
        defer { self.lock.signal() }

        let itemsToDelete = instances
        instances.removeAll()
        for item in itemsToDelete {
            item.dispose()
        }
        return itemsToDelete.map { $0.dataCaptureView }
    }

    public func addOverlayToView(_ view: DataCaptureView, overlay: DataCaptureOverlay) {
        self.lock.wait()
        defer { self.lock.signal() }
        
        if let wrapper = instances.first(where: { $0.dataCaptureView === view }) {
            wrapper.addOverlay(overlay)
        }
    }

    public func removeOverlayFromView(_ view: DataCaptureView, overlay: DataCaptureOverlay) {
        self.lock.wait()
        defer { self.lock.signal() }
        
        if let wrapper = instances.first(where: { $0.dataCaptureView === view }) {
            wrapper.removeOverlay(overlay)
        }
    }
    
    public func removeOverlayFromTopmostView(overlay: DataCaptureOverlay) {        
        topmostWrapper?.removeOverlay(overlay)
    }

    public func removeAllOverlaysFromView(_ view: DataCaptureView) {
        self.lock.wait()
        defer { self.lock.signal() }
        
        if let wrapper = instances.first(where: { $0.dataCaptureView === view }) {
            wrapper.removeAllOverlays()
        }
    }

    public func findFirstOverlayOfType<T: DataCaptureOverlay>() -> T? {
        return topmostWrapper?.findFirstOfType()
    }
}
