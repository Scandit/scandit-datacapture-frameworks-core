/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore
import XCTest

@testable import ScanditFrameworksCore

/// Covers the production residual payload only. `orientation`, `isExpanded`,
/// `isAlwaysExpanded` and `accessibilityHint` ship as generated static values and are
/// checked against the SoT by the defaults drift test - asserting them off
/// `ZoomSwitchControlWideDefaults` here would be the test target checking its own output.
final class ZoomSwitchControlDefaultsTests: XCTestCase {

    private var defaults: [String: Any?]!

    override func setUp() {
        super.setUp()
        let control = ZoomSwitchControl()
        defaults = ZoomSwitchControlDefaults(control: control).toDynamicEncodable()
    }

    func testContainsAccessibilityLabelKey() {
        XCTAssertNotNil(defaults[ZoomSwitchControlDefaults.Keys.accessibilityLabel])
    }

    func testAccessibilityLabelIsNonEmpty() {
        let label = defaults[ZoomSwitchControlDefaults.Keys.accessibilityLabel] as? String
        XCTAssertNotNil(label)
        XCTAssertFalse(label!.isEmpty)
    }

    func testDynamicPayloadCarriesOnlyTheResidualKey() {
        XCTAssertEqual(Set(defaults.keys), [ZoomSwitchControlDefaults.Keys.accessibilityLabel])
    }
}
