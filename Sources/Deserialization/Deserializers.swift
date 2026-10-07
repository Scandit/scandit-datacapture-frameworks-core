/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public final class Deserializers {

    public final class Factory {
        private init() {}

        private static var modeDeserializers: [DataCaptureModeDeserializer] = []

        public static func add(_ modeDeserializer: DataCaptureModeDeserializer) {
            if modeDeserializers.firstIndex(where: { $0 === modeDeserializer }) != nil {
                return
            }
            modeDeserializers.append(modeDeserializer)
        }

        public static func remove(_ modeDeserializer: DataCaptureModeDeserializer) {
            if let indexToRemove = modeDeserializers.firstIndex(where: { $0 === modeDeserializer }) {
                modeDeserializers.remove(at: indexToRemove)
            }
        }

        public static func clearDeserializers() {
            modeDeserializers.removeAll()
        }

        public static func create(frameSourceDeserializerDelegate: FrameSourceDeserializerDelegate) -> Deserializers {
            Deserializers(
                modeDeserializers: modeDeserializers,
                componentDeserializers: [],
                frameSourceDeserializerDelegate: frameSourceDeserializerDelegate
            )
        }
    }

    private let modeDeserializers: [DataCaptureModeDeserializer]
    private let componentDeserializers: [DataCaptureComponentDeserializer]
    let frameSourceDeserializer: FrameSourceDeserializer
    let dataCaptureViewDeserializer: DataCaptureViewDeserializer
    let dataCaptureContextDeserializer: DataCaptureContextDeserializer

    fileprivate init(
        modeDeserializers: [DataCaptureModeDeserializer],
        componentDeserializers: [DataCaptureComponentDeserializer],
        frameSourceDeserializerDelegate: FrameSourceDeserializerDelegate
    ) {
        self.modeDeserializers = modeDeserializers
        self.componentDeserializers = componentDeserializers
        frameSourceDeserializer = FrameSourceDeserializer(modeDeserializers: modeDeserializers)
        frameSourceDeserializer.delegate = frameSourceDeserializerDelegate
        dataCaptureViewDeserializer = DataCaptureViewDeserializer(modeDeserializers: modeDeserializers)
        dataCaptureContextDeserializer = DataCaptureContextDeserializer(
            frameSourceDeserializer: frameSourceDeserializer,
            viewDeserializer: dataCaptureViewDeserializer,
            modeDeserializers: modeDeserializers,
            componentDeserializers: componentDeserializers
        )
        dataCaptureContextDeserializer.avoidThreadDependencies = true
    }
}
