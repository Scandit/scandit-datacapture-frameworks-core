import Foundation
import ScanditCaptureCore
import UIKit

public struct MacroModeControlDefaults: DefaultsEncodable {
    private let control: MacroModeControl

    public init(control: MacroModeControl) {
        self.control = control
    }

    public func toEncodable() -> [String: Any?] {
        [
            "icon": [
                "auto": control.autoImage.pngBase64String,
                "off": control.offImage.pngBase64String,
                "on": control.onImage.pngBase64String,
            ],
            "accessibilityLabelWhenAuto": control.accessibilityLabelWhenAuto,
            "accessibilityHintWhenAuto": control.accessibilityHintWhenAuto,
            "accessibilityLabelWhenOff": control.accessibilityLabelWhenOff,
            "accessibilityHintWhenOff": control.accessibilityHintWhenOff,
            "accessibilityLabelWhenOn": control.accessibilityLabelWhenOn,
            "accessibilityHintWhenOn": control.accessibilityHintWhenOn,
        ]
    }
}

private extension UIImage {
    var pngBase64String: String? {
        pngData()?.base64EncodedString()
    }
}
