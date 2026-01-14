/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct EncodableRectangularViewfinder: DefaultsEncodable {
    init(
        size: String,
        color: UIColor,
        style: String,
        lineStyle: String,
        dimming: CGFloat,
        animation: RectangularViewfinderAnimation? = nil,
        disabledDimming: CGFloat,
        disabledColor: UIColor
    ) {
        self.size = size
        self.color = color
        self.style = style
        self.lineStyle = lineStyle
        self.dimming = dimming
        self.animation = animation
        self.disabledDimming = disabledDimming
        self.disabledColor = disabledColor
    }
    
    private let size: String
    private let color: UIColor
    private let style: String
    private let lineStyle: String
    private let dimming: CGFloat
    private let animation: RectangularViewfinderAnimation?
    private let disabledDimming: CGFloat
    private let disabledColor: UIColor

    init(viewfinder: RectangularViewfinder) {
        size = viewfinder.sizeWithUnitAndAspect.jsonString
        color = viewfinder.color
        style = viewfinder.style.jsonString
        lineStyle = viewfinder.lineStyle.jsonString
        dimming = viewfinder.dimming
        animation = viewfinder.animation
        disabledDimming = viewfinder.disabledDimming
        disabledColor = viewfinder.disabledColor
    }

    func toEncodable() -> [String: Any?] {
        [
            "size":             size,
            "color":            color.sdcHexString,
            "style":            style,
            "lineStyle":        lineStyle,
            "dimming":          dimming,
            "animation":        animation?.jsonString,
            "disabledDimming":  disabledDimming,
            "disabledColor":    disabledColor.sdcHexString
        ]
    }
}
