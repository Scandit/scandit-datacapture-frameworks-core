/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public final class DefaultFrameworksCaptureContext {
    private init() {}

    private let contextLock = NSLock()
    private var initialized = false
    private var deserializers: Deserializers?

    public var context: DataCaptureContext? {
        return initialized ? DataCaptureContext.sharedInstance : nil
    }

    func initialize(
        json: String,
        frameSourceListener: FrameSourceListener,
        frameSourceDeserializerListener: FrameworksFrameSourceDeserializer,
        dataCaptureContextListener: DataCaptureContextListener
    ) throws -> DataCaptureContext  {
        contextLock.lock()
        defer { contextLock.unlock() }

        deserializers = Deserializers.Factory.create(frameSourceDeserializerDelegate: frameSourceDeserializerListener)

        let data = try DataCaptureContextData.from(jsonString: json)

        // Deserialize Settings
        let dataCaptureContextSettings = DataCaptureContextSettings()
        if let settings = data.settings {
            for (key, value) in settings {
                dataCaptureContextSettings.set(value: value, forProperty: key)
            }
        }

        // Init Singleton
        let dcContext = DataCaptureContext.initialize(
            licenseKey: data.licenseKey,
            externalID: data.externalId,
            deviceName: data.deviceName,
            frameworkName: data.framework,
            frameworkVersion: data.frameworkVersion,
            settings: dataCaptureContextSettings
        )

        // Proceed with FrameSource
        if let frameSourceJson = data.frameSource {
            if let frameSource = try deserializers?.frameSourceDeserializer.frameSource(fromJSONString: frameSourceJson) {
                dcContext.setFrameSource(frameSource)
            }
        }

        dcContext.addListener(dataCaptureContextListener)
        initialized = true
        return dcContext
    }

    func update(json: String) throws {
        guard initialized else { fatalError("DataCaptureContextNotInitialized") }

        let data = try DataCaptureContextData.from(jsonString: json)

        // Deserialize Settings
        if let settings = data.settings {
            let dataCaptureContextSettings = DataCaptureContextSettings()
            for (key, value) in settings {
                dataCaptureContextSettings.set(value: value, forProperty: key)
            }
            context?.applySettings(dataCaptureContextSettings)
        }

        if let frameSourceJson = data.frameSource {
            if let frameSource = try deserializers?.frameSourceDeserializer.frameSource(fromJSONString: frameSourceJson) {
                context?.setFrameSource(frameSource)
            }
        }
    }

    func release(dataCaptureContextListener: DataCaptureContextListener) {
        context?.removeListener(dataCaptureContextListener)
        context?.dispose()
        initialized = false
    }

    public func addMode(mode: DataCaptureMode) {
        guard initialized else { fatalError("DataCaptureContextNotInitialized") }
        context?.addMode(mode)
    }

    public func removeMode(mode: DataCaptureMode) {
        context?.removeMode(mode)
    }

    public func removeAllModes() {
        context?.removeAllModes()
    }

    public static let shared = DefaultFrameworksCaptureContext()
}

