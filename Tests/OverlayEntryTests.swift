/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class OverlayEntryTests: XCTestCase {

    // MARK: - from(overlayDict:)

    func testFromReturnsEntryWithCorrectKeyAndType() {
        let dict: [String: Any] = ["type": "labelCapture", "modeId": 1]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.key, "labelCapture:1")
        XCTAssertEqual(entry?.type, "labelCapture")
    }

    func testFromUsesDefaultModeIdWhenMissing() {
        let dict: [String: Any] = ["type": "barcodeCapture"]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.key, "barcodeCapture:-1")
        XCTAssertEqual(entry?.type, "barcodeCapture")
    }

    func testFromReturnsNilWhenTypeMissing() {
        let dict: [String: Any] = ["modeId": 1]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNil(entry)
    }

    func testFromPreservesFullJsonString() {
        let dict: [String: Any] = [
            "type": "labelCapture",
            "modeId": 2,
            "extraField": "someValue",
        ]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNotNil(entry)
        let reparsed =
            try? JSONSerialization.jsonObject(
                with: entry!.jsonString.data(using: .utf8)!
            ) as? [String: Any]
        XCTAssertNotNil(reparsed)
        XCTAssertEqual(reparsed?["type"] as? String, "labelCapture")
        XCTAssertEqual(reparsed?["modeId"] as? Int, 2)
        XCTAssertEqual(reparsed?["extraField"] as? String, "someValue")
    }

    func testFromHandlesModeIdOfZero() {
        let dict: [String: Any] = ["type": "barcodeCapture", "modeId": 0]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.key, "barcodeCapture:0")
    }

    func testFromHandlesNegativeModeId() {
        let dict: [String: Any] = ["type": "barcodeCapture", "modeId": -5]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.key, "barcodeCapture:-5")
    }

    func testFromHandlesLargeModeId() {
        let dict: [String: Any] = ["type": "barcodeCapture", "modeId": Int.max]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.key, "barcodeCapture:\(Int.max)")
    }

    func testFromWithEmptyDictReturnsNil() {
        let dict: [String: Any] = [:]

        let entry = OverlayEntry.from(overlayDict: dict)

        XCTAssertNil(entry)
    }
}
