/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct EncodableLaserlineViewFinder: DefaultsEncodable {
    let size: SizeWithUnit
    let style: String
    let enabledColor: String
    let disabledColor: String

    init(size: SizeWithUnit,
         style: String,
         enabledColor: String,
         disabledColor: String) {
        self.size = size
        self.style = style
        self.enabledColor = enabledColor
        self.disabledColor = disabledColor
    }

    func toEncodable() -> [String: Any?] {
        [
            "width": size.width.jsonString,
            "style": style,
            "enabledColor": enabledColor,
            "disabledColor": disabledColor
        ]
    }
}

struct LaserlineViewfinderDefaults: DefaultsEncodable {
    func toEncodable() -> [String: Any?] {
        return [
            "defaultStyle": "legacy",
            "styles": [
                "animated": EncodableLaserlineViewFinder(
                    size: .init(
                        width: .init(
                            value: 0.800000011920929,
                            unit: .fraction
                        ),
                        height: .init()
                    ),
                    style: "animated",
                    enabledColor: "ffffffff" ,
                    disabledColor:"00000000"
                ).toEncodable(),
                "legacy": EncodableLaserlineViewFinder(
                    size: .init(
                        width: .init(
                            value: 0.75,
                            unit: .fraction
                        ),
                        height: .init()
                    ),
                    style: "legacy",
                    enabledColor: "2ec1ceff" ,
                    disabledColor:"2ec1ceff"
                ).toEncodable(),
            ]
        ]
    }
}

extension RectangularViewfinderStyle: CaseIterable {
    public static var allCases: [RectangularViewfinderStyle] {
        [ .rounded, .square]
    }
}

extension EncodableRectangularViewfinder {
    public static let legacyViewFinder = EncodableRectangularViewfinder(
        size: "{\"height\":{\"unit\":\"fraction\",\"value\":0.32},\"width\":{\"unit\":\"fraction\",\"value\":0.80}}",
        color: UIColor(sdcHexString: "ffffffff")!,
        style: "legacy",
        lineStyle: "light",
        dimming: 0,
        disabledDimming: 0,
        disabledColor: UIColor(sdcHexString: "00000000")!
    )
}

struct RectangularViewfinderDefaults: DefaultsEncodable {
    func toEncodable() -> [String: Any?] {
        var allViewFinders = Dictionary(uniqueKeysWithValues: RectangularViewfinderStyle.allCases.map {
            ($0.jsonString, EncodableRectangularViewfinder(viewfinder: RectangularViewfinder(style: $0)).toEncodable())
        })

        // Deprecated RectangularViewFinderStyle
        allViewFinders["legacy"] = EncodableRectangularViewfinder.legacyViewFinder.toEncodable()

        return [
            "defaultStyle": "legacy",
            "styles": allViewFinders
        ]
    }
}

extension CameraPosition: CaseIterable {
    public static var allCases: [CameraPosition] {
        [.worldFacing, .userFacing, .unspecified]
    }
}

struct CoreDefaults: DefaultsEncodable {
    private let cameraDefaults: CameraDefaults
    private let dataCaptureViewDefaults: DataCaptureViewDefaults
    private let laserlineViewfinderDefaults = LaserlineViewfinderDefaults ()
    private let rectangularViewfinderDefaults: RectangularViewfinderDefaults
    private let aimerViewfinderDefauls: EncodableAimerViewfinder
    private let brushDefaults: EncodableBrush
    private let spotlightViewfinderDefaults: SpotlightViewfinderDefaults

    init(cameraDefaults: CameraDefaults,
         dataCaptureViewDefaults: DataCaptureViewDefaults,
         rectangularViewfinderDefaults: RectangularViewfinderDefaults,
         aimerViewfinderDefauls: EncodableAimerViewfinder,
         brushDefaults: EncodableBrush,
         spotlightViewfinderDefaults: SpotlightViewfinderDefaults) {
        self.cameraDefaults = cameraDefaults
        self.dataCaptureViewDefaults = dataCaptureViewDefaults
        self.rectangularViewfinderDefaults = rectangularViewfinderDefaults
        self.aimerViewfinderDefauls = aimerViewfinderDefauls
        self.brushDefaults = brushDefaults
        self.spotlightViewfinderDefaults = spotlightViewfinderDefaults
    }

    func toEncodable() -> [String: Any?] {
        [
            "Version": DataCaptureVersion.version(),
            "deviceID": DataCaptureContext.deviceID,
            "Camera": cameraDefaults.toEncodable(),
            "DataCaptureView": dataCaptureViewDefaults.toEncodable(),
            "LaserlineViewfinder": laserlineViewfinderDefaults.toEncodable(),
            "RectangularViewfinder": rectangularViewfinderDefaults.toEncodable(),
            "AimerViewfinder": aimerViewfinderDefauls.toEncodable(),
            "Brush": brushDefaults.toEncodable(),
            "SpotlightViewfinder": spotlightViewfinderDefaults.toEncodable()
        ]
    }

    static let shared: CoreDefaults = {
        let cameraDefaults = CameraDefaults(cameraSettingsDefaults: EncodableCameraSettings(cameraSettings: CameraSettings()),
                                            defaultPosition: Camera.default?.position,
                                            availablePositions: CameraPosition.allCases.compactMap { Camera(position: $0)?.position })
        let rectangularViewfinderDefaults = RectangularViewfinderDefaults()
        return CoreDefaults(cameraDefaults: cameraDefaults,
                            dataCaptureViewDefaults: DataCaptureViewDefaults(view: DataCaptureView(frame: .zero)),
                            rectangularViewfinderDefaults: rectangularViewfinderDefaults,
                            aimerViewfinderDefauls: EncodableAimerViewfinder(viewfinder: AimerViewfinder()),
                            brushDefaults: EncodableBrush(brush: .transparent),
                            spotlightViewfinderDefaults: SpotlightViewfinderDefaults())
    }()
}
