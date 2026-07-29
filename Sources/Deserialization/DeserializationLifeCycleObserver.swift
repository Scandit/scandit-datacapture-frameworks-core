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
    // Note: These throwing methods trigger a Swift 6.1.2 compiler crash when used with optional chaining
    // Workaround: Use Objective-C runtime method dispatch to avoid optional chaining
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
                $0.dataCaptureView?(deserialized: view)
            }
        }
    }

    public func dispatchDataCaptureViewRemoved(view: DataCaptureView) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(removed:))) {
                $0.dataCaptureView?(removed: view)
            }
        }
    }

    func dispatchDataCaptureContextDisposed() {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.didDisposeDataCaptureContext)) {
                $0.didDisposeDataCaptureContext?()
            }
        }
    }

    func dispatchAddModeToContext(modeJson: String) throws {
        let observersList = observers.compactMap { $0 as? DeserializationLifeCycleObserver }
        for observer in observersList
        where observer.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureContext(addMode:))) {
            // Workaround for Swift 6.1.2 compiler crash with try + optional chaining on @objc optional throwing methods
            // Use a non-optional local closure to call the method without optional chaining
            let callMethod: (String) throws -> Void = { [weak observer] modeJson in
                guard let observer = observer else { return }
                // Safe to force unwrap since we already checked responds(to:)
                // swift-format-ignore: NeverForceUnwrap
                try observer.dataCaptureContext!(addMode: modeJson)
            }
            try callMethod(modeJson)
        }
    }

    func dispatchRemoveModeFromContext(modeJson: String) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureContext(removeMode:))) {
                $0.dataCaptureContext?(removeMode: modeJson)
            }
        }
    }

    func dispatchAllModesRemovedFromContext() {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureContextAllModeRemoved)) {
                $0.dataCaptureContextAllModeRemoved?()
            }
        }
    }

    func dispatchAddOverlayToView(view: FrameworksDataCaptureView, overlayJson: String) throws {
        let observersList = observers.compactMap { $0 as? DeserializationLifeCycleObserver }
        for observer in observersList
        where observer.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(addOverlay:to:))) {
            // Workaround for Swift 6.1.2 compiler crash with try + optional chaining on @objc optional throwing methods
            // Use a non-optional local closure to call the method without optional chaining
            let callMethod: (String, FrameworksDataCaptureView) throws -> Void = { [weak observer] overlayJson, view in
                guard let observer = observer else { return }
                // Safe to force unwrap since we already checked responds(to:)
                // swift-format-ignore: NeverForceUnwrap
                try observer.dataCaptureView!(addOverlay: overlayJson, to: view)
            }
            try callMethod(overlayJson, view)
        }
    }

    public func dispatchOverlayRemoved(overlay: DataCaptureOverlay) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(removedOverlay:))) {
                $0.dataCaptureView?(removedOverlay: overlay)
            }
        }
    }
}
