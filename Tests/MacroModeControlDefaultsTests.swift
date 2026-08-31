import ScanditCaptureCore
import XCTest

@testable import ScanditFrameworksCore

final class MacroModeControlDefaultsTests: XCTestCase {

    private var defaults: [String: Any?]!

    override func setUp() {
        super.setUp()
        let control = MacroModeControl()
        defaults = MacroModeControlDefaults(control: control).toEncodable()
    }

    func testContainsIconKey() {
        XCTAssertNotNil(defaults["icon"] as Any?)
    }

    func testIconContainsAutoOffOnEntries() {
        let icon = defaults["icon"] as? [String: Any?]
        XCTAssertNotNil(icon)
        XCTAssertTrue(icon!.keys.contains("auto"))
        XCTAssertTrue(icon!.keys.contains("off"))
        XCTAssertTrue(icon!.keys.contains("on"))
    }

    func testDefaultImagesAreEncodedAsBase64() {
        let icon = defaults["icon"] as? [String: Any?]
        XCTAssertNotNil(icon?["auto"] as? String)
        XCTAssertNotNil(icon?["off"] as? String)
        XCTAssertNotNil(icon?["on"] as? String)
    }

    func testContainsAccessibilityLabelKeys() {
        XCTAssertNotNil(defaults["accessibilityLabelWhenAuto"] as Any?)
        XCTAssertNotNil(defaults["accessibilityLabelWhenOff"] as Any?)
        XCTAssertNotNil(defaults["accessibilityLabelWhenOn"] as Any?)
    }

    func testContainsAccessibilityHintKeys() {
        XCTAssertNotNil(defaults["accessibilityHintWhenAuto"] as Any?)
        XCTAssertNotNil(defaults["accessibilityHintWhenOff"] as Any?)
        XCTAssertNotNil(defaults["accessibilityHintWhenOn"] as Any?)
    }

    func testAccessibilityLabelsAreNonEmpty() {
        let label = (defaults["accessibilityLabelWhenAuto"] as? String)
        XCTAssertNotNil(label)
        XCTAssertFalse(label!.isEmpty)
    }
}
