/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore
import XCTest

@testable import ScanditFrameworksCore

final class ZoomSwitchControlDefaultsTests: XCTestCase {

    private var defaults: [String: Any?]!

    override func setUp() {
        super.setUp()
        let control = ZoomSwitchControl()
        defaults = ZoomSwitchControlDefaults(control: control).toEncodable()
    }

    // MARK: - Keys presence

    func testContainsOrientationKey() {
        XCTAssertNotNil(defaults["orientation"])
    }

    func testContainsIsAlwaysExpandedKey() {
        XCTAssertNotNil(defaults["isAlwaysExpanded"])
    }

    func testContainsIsExpandedKey() {
        XCTAssertNotNil(defaults["isExpanded"])
    }

    func testContainsAccessibilityLabelKey() {
        XCTAssertNotNil(defaults["accessibilityLabel"])
    }

    func testContainsAccessibilityHintKey() {
        XCTAssertNotNil(defaults["accessibilityHint"])
    }

    // MARK: - Default values

    func testOrientationIsDefaultByDefault() {
        XCTAssertEqual(defaults["orientation"] as? String, "default")
    }

    func testIsAlwaysExpandedIsFalseByDefault() {
        XCTAssertEqual(defaults["isAlwaysExpanded"] as? Bool, false)
    }

    func testIsExpandedIsFalseByDefault() {
        XCTAssertEqual(defaults["isExpanded"] as? Bool, false)
    }

    func testAccessibilityLabelIsNonEmpty() {
        let label = defaults["accessibilityLabel"] as? String
        XCTAssertNotNil(label)
        XCTAssertFalse(label!.isEmpty)
    }

    func testAccessibilityHintIsNonEmpty() {
        let hint = defaults["accessibilityHint"] as? String
        XCTAssertNotNil(hint)
        XCTAssertFalse(hint!.isEmpty)
    }

    // MARK: - Orientation JSON string values

    func testOrientationValueIsValidJsonString() {
        let orientation = defaults["orientation"] as? String
        XCTAssertTrue(
            orientation == "horizontal" || orientation == "vertical" || orientation == "default",
            "orientation should be 'horizontal', 'vertical', or 'default', was: \(String(describing: orientation))"
        )
    }
}
