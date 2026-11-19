/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class DataCaptureViewCreationDataTests: XCTestCase {

    // MARK: - Basic parsing

    func testFromJsonParsesViewId() {
        let json = """
            {"viewId": 42}
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.viewId, 42)
    }

    func testFromJsonParsesParentIdWhenPresent() {
        let json = """
            {"viewId": 1, "parentId": 99}
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.parentId, 99)
    }

    func testFromJsonReturnsNilParentIdWhenNotPresent() {
        let json = """
            {"viewId": 1}
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertNil(data.parentId)
    }

    // MARK: - Overlay parsing

    func testFromJsonParsesOverlaysIntoOverlayEntryList() {
        let json = """
            {
                "viewId": 1,
                "overlays": [
                    {"type": "labelCapture", "modeId": 1},
                    {"type": "barcodeCapture", "modeId": 2}
                ]
            }
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.overlays.count, 2)
        XCTAssertEqual(data.overlays[0].key, "labelCapture:1")
        XCTAssertEqual(data.overlays[0].type, "labelCapture")
        XCTAssertEqual(data.overlays[1].key, "barcodeCapture:2")
        XCTAssertEqual(data.overlays[1].type, "barcodeCapture")
    }

    func testFromJsonReturnsEmptyOverlaysWhenNoOverlaysKey() {
        let json = """
            {"viewId": 1}
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertTrue(data.overlays.isEmpty)
    }

    func testFromJsonReturnsEmptyOverlaysWhenOverlaysArrayIsEmpty() {
        let json = """
            {"viewId": 1, "overlays": []}
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertTrue(data.overlays.isEmpty)
    }

    func testFromJsonStripsOverlaysFromViewJson() {
        let json = """
            {
                "viewId": 1,
                "overlays": [{"type": "labelCapture", "modeId": 1}]
            }
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        let viewJsonData = data.viewJson.data(using: .utf8)!
        let viewDict = try! JSONSerialization.jsonObject(with: viewJsonData) as! [String: Any]
        XCTAssertNil(viewDict["overlays"])
    }

    func testFromJsonSkipsOverlaysWithoutType() {
        let json = """
            {
                "viewId": 1,
                "overlays": [
                    {"type": "labelCapture", "modeId": 1},
                    {"modeId": 2}
                ]
            }
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.overlays.count, 1)
        XCTAssertEqual(data.overlays[0].key, "labelCapture:1")
    }

    func testFromJsonPreservesOverlayJsonContent() {
        let json = """
            {
                "viewId": 1,
                "overlays": [
                    {"type": "labelCapture", "modeId": 1, "brush": {"fill": "#00FF00"}}
                ]
            }
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        let overlayData = data.overlays[0].jsonString.data(using: .utf8)!
        let overlayDict = try! JSONSerialization.jsonObject(with: overlayData) as! [String: Any]
        let brush = overlayDict["brush"] as! [String: Any]
        XCTAssertEqual(brush["fill"] as? String, "#00FF00")
    }

    func testFromJsonUsesDefaultModeIdForOverlaysWithoutModeId() {
        let json = """
            {
                "viewId": 1,
                "overlays": [{"type": "labelCapture"}]
            }
            """

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.overlays.count, 1)
        XCTAssertEqual(data.overlays[0].key, "labelCapture:-1")
    }

    // MARK: - Invalid JSON

    func testFromJsonWithInvalidJsonReturnsDefaults() {
        let json = "not valid json"

        let data = DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.viewId, 0)
        XCTAssertNil(data.parentId)
        XCTAssertEqual(data.viewJson, "{}")
        XCTAssertTrue(data.overlays.isEmpty)
    }

    func testFromJsonWithEmptyStringReturnsDefaults() {
        let data = DataCaptureViewCreationData.fromJson("")

        XCTAssertEqual(data.viewId, 0)
        XCTAssertTrue(data.overlays.isEmpty)
    }
}
