/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore
import XCTest

@testable import ScanditFrameworksCore

/// SDC-32178: the residual `Camera` and `ZoomSwitchControl` keys must be deep-equal to the wide
/// blob, which the drift test pins to the SoT. A key renamed on both sides at once still passes.
/// Android mirror: `CoreDefaultsDynamicTest.kt`.
final class CoreDefaultsDynamicTests: XCTestCase {

    func testDynamicDefaultsMatchTheWideDefaultsForEveryResidualKey() throws {
        let wide = CoreWideDefaults.shared.toEncodable()
        let dynamic = CoreDefaults.shared.toDynamicEncodable()

        XCTAssertEqual(
            Set(dynamic.keys),
            Set(["Version", "deviceID", "Camera", "ZoomSwitchControl", "MacroModeControl"])
        )

        let wideCamera = try XCTUnwrap(wide["Camera"] as? [String: Any?])
        let dynamicCamera = try XCTUnwrap(dynamic["Camera"] as? [String: Any?])
        XCTAssertEqual(Set(dynamicCamera.keys), Set(["defaultPosition", "availablePositions"]))
        assertResidualMatches(wide: wideCamera, dynamic: dynamicCamera, key: "defaultPosition", block: "Camera")
        assertResidualMatches(wide: wideCamera, dynamic: dynamicCamera, key: "availablePositions", block: "Camera")

        let wideZoom = try XCTUnwrap(wide["ZoomSwitchControl"] as? [String: Any?])
        let dynamicZoom = try XCTUnwrap(dynamic["ZoomSwitchControl"] as? [String: Any?])
        XCTAssertEqual(Set(dynamicZoom.keys), Set(["accessibilityLabel"]))
        assertResidualMatches(
            wide: wideZoom,
            dynamic: dynamicZoom,
            key: "accessibilityLabel",
            block: "ZoomSwitchControl"
        )

        // Compared as NSDictionary, not String(describing:): a stringified compare makes a
        // String and an NSNumber holding the same digits look equal, which is exactly the
        // type-change drift this assertion exists to catch (SDC-32173).
        let wideMacro = try XCTUnwrap(wide["MacroModeControl"] as? [String: Any?])
        let dynamicMacro = try XCTUnwrap(dynamic["MacroModeControl"] as? [String: Any?])
        XCTAssertEqual(
            NSDictionary(dictionary: wideMacro as [AnyHashable: Any]),
            NSDictionary(dictionary: dynamicMacro as [AnyHashable: Any])
        )
    }

    /// Asserts the residual value is the SAME in both payloads, without requiring it to be
    /// non-nil: several of these keys are device-probed (`defaultPosition`, `availablePositions`)
    /// and are legitimately nil on a simulator, so unwrapping them here would fail for reasons
    /// that have nothing to do with drift.
    ///
    /// What it does catch: the wide side dropping the key (checked explicitly, since a missing key
    /// and a nil value are both `nil` through a subscript), and a value that stops bridging to
    /// `NSObject` on one side only.
    private func assertResidualMatches(
        wide: [String: Any?],
        dynamic: [String: Any?],
        key: String,
        block: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            wide.keys.contains(key),
            "the wide \(block) block no longer carries '\(key)' - the dynamic payload is not a selection of it",
            file: file,
            line: line
        )
        let wideValue = wide[key] ?? nil
        let dynamicValue = dynamic[key] ?? nil
        XCTAssertEqual(
            wideValue == nil,
            dynamicValue == nil,
            "dynamic \(block)['\(key)'] is nil on one side only",
            file: file,
            line: line
        )
        XCTAssertEqual(
            wideValue as? NSObject,
            dynamicValue as? NSObject,
            "dynamic \(block)['\(key)'] differs from the wide defaults",
            file: file,
            line: line
        )
        if wideValue != nil {
            XCTAssertNotNil(
                wideValue as? NSObject,
                "\(block)['\(key)'] no longer bridges to NSObject - the comparison above would pass vacuously",
                file: file,
                line: line
            )
        }
    }
}
