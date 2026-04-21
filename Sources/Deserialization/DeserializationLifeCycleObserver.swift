/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

@objc
public protocol DeserializationLifeCycleObserver: NSObjectProtocol {
    @objc optional func didDisposeDataCaptureContext()
    @objc optional func dataCaptureView(deserialized view: DataCaptureView?)
    @objc optional func dataCaptureView(removed view: DataCaptureView)
    @objc optional func dataCaptureContext(addMode modeJson: String) throws
    @objc optional func dataCaptureContext(removeMode modeJson: String)
    @objc optional func dataCaptureContextAllModeRemoved()
    @objc optional func dataCaptureView(addOverlay overlayJson: String, to view: FrameworksDataCaptureView) throws
    @objc optional func dataCaptureView(removedOverlay overlay: DataCaptureOverlay)
}

public final class DeserializationLifeCycleDispatcher {
    public static let shared = DeserializationLifeCycleDispatcher()

    private init() {}

    private var observers = NSMutableSet()

    public func attach(observer: DeserializationLifeCycleObserver) {
        observers.add(observer)
    }

    public func detach(observer: DeserializationLifeCycleObserver) {
        observers.remove(observer)
    }

    func dispatchDataCaptureViewDeserialized(view: DataCaptureView?) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(deserialized:))) {
                $0.dataCaptureView!(deserialized: view)
            }
        }
    }
    
    public func dispatchDataCaptureViewRemoved(view: DataCaptureView) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(removed:))) {
                $0.dataCaptureView!(removed: view)
            }
        }
    }

    func dispatchDataCaptureContextDisposed() {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.didDisposeDataCaptureContext)) {
                $0.didDisposeDataCaptureContext!()
            }
        }
    }
    
    func dispatchAddModeToContext(modeJson: String) throws {
        try observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureContext(addMode:))) {
                try $0.dataCaptureContext!(addMode: modeJson)
            }
        }
    }
    
    func dispatchRemoveModeFromContext(modeJson: String)  {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureContext(removeMode:))) {
                $0.dataCaptureContext!(removeMode: modeJson)
            }
        }
    }
    
    func dispatchAllModesRemovedFromContext()  {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureContextAllModeRemoved)) {
                $0.dataCaptureContextAllModeRemoved!()
            }
        }
    }
    
    func dispatchAddOverlayToView(view: FrameworksDataCaptureView, overlayJson: String) throws {
        try observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(addOverlay:to:))) {
                try $0.dataCaptureView!(addOverlay: overlayJson, to: view)
            }
        }
    }
    
    public func dispatchOverlayRemoved(overlay: DataCaptureOverlay) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(removedOverlay:))) {
                $0.dataCaptureView!(removedOverlay: overlay)
            }
        }
    }
}
