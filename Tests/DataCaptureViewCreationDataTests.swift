/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class DataCaptureViewCreationDataTests: XCTestCase {

    // MARK: - Basic parsing

    func testFromJsonParsesViewId() throws {
        let json = """
            {"viewId": 42}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.viewId, 42)
    }

    func testFromJsonParsesParentIdWhenPresent() throws {
        let json = """
            {"viewId": 1, "parentId": 99}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.parentId, 99)
    }

    func testFromJsonReturnsNilParentIdWhenNotPresent() throws {
        let json = """
            {"viewId": 1}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertNil(data.parentId)
    }

    // MARK: - Overlay parsing

    func testFromJsonParsesOverlaysIntoOverlayEntryList() throws {
        let json = """
            {
                "viewId": 1,
                "overlays": [
                    {"type": "labelCapture", "modeId": 1},
                    {"type": "barcodeCapture", "modeId": 2}
                ]
            }
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.overlays.count, 2)
        XCTAssertEqual(data.overlays[0].key, "labelCapture:1")
        XCTAssertEqual(data.overlays[0].type, "labelCapture")
        XCTAssertEqual(data.overlays[1].key, "barcodeCapture:2")
        XCTAssertEqual(data.overlays[1].type, "barcodeCapture")
    }

    func testFromJsonReturnsEmptyOverlaysWhenNoOverlaysKey() throws {
        let json = """
            {"viewId": 1}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertTrue(data.overlays.isEmpty)
    }

    func testFromJsonReturnsEmptyOverlaysWhenOverlaysArrayIsEmpty() throws {
        let json = """
            {"viewId": 1, "overlays": []}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertTrue(data.overlays.isEmpty)
    }

    func testFromJsonStripsOverlaysFromViewJson() throws {
        let json = """
            {
                "viewId": 1,
                "overlays": [{"type": "labelCapture", "modeId": 1}]
            }
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        let viewJsonData = data.viewJson.data(using: .utf8)!
        let viewDict = try! JSONSerialization.jsonObject(with: viewJsonData) as! [String: Any]
        XCTAssertNil(viewDict["overlays"])
    }

    func testFromJsonSkipsOverlaysWithoutType() throws {
        let json = """
            {
                "viewId": 1,
                "overlays": [
                    {"type": "labelCapture", "modeId": 1},
                    {"modeId": 2}
                ]
            }
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.overlays.count, 1)
        XCTAssertEqual(data.overlays[0].key, "labelCapture:1")
    }

    func testFromJsonPreservesOverlayJsonContent() throws {
        let json = """
            {
                "viewId": 1,
                "overlays": [
                    {"type": "labelCapture", "modeId": 1, "brush": {"fill": "#00FF00"}}
                ]
            }
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        let overlayData = data.overlays[0].jsonString.data(using: .utf8)!
        let overlayDict = try! JSONSerialization.jsonObject(with: overlayData) as! [String: Any]
        let brush = overlayDict["brush"] as! [String: Any]
        XCTAssertEqual(brush["fill"] as? String, "#00FF00")
    }

    func testFromJsonUsesDefaultModeIdForOverlaysWithoutModeId() throws {
        let json = """
            {
                "viewId": 1,
                "overlays": [{"type": "labelCapture"}]
            }
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.overlays.count, 1)
        XCTAssertEqual(data.overlays[0].key, "labelCapture:-1")
    }

    // MARK: - Invalid JSON

    func testFromJsonWithInvalidJsonReturnsDefaults() throws {
        let json = "not valid json"

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.viewId, 0)
        XCTAssertNil(data.parentId)
        XCTAssertEqual(data.viewJson, "{}")
        XCTAssertTrue(data.overlays.isEmpty)
    }

    func testFromJsonWithEmptyStringReturnsDefaults() throws {
        let data = try DataCaptureViewCreationData.fromJson("")

        XCTAssertEqual(data.viewId, 0)
        XCTAssertTrue(data.overlays.isEmpty)
    }

    // MARK: - Generated-parse fallback (SDC-33315)
    //
    // Mirrors `DataCaptureViewCreationDataFallbackTest.kt` on the Android side. The generated
    // `SchemaTypes.DataCaptureViewPayload` decode enforces `additionalProperties: false` and
    // strict numeric typing. Two failure classes are handled differently:
    //
    // - An unknown key is a schema-vs-wire drift risk (SDC-32646), not proof the payload is
    //   malformed, so it alone degrades to the legacy parse.
    // - A declared field with an invalid value is never tolerated, with or without a
    //   co-occurring unknown key. `requireIntegral` re-validates `viewId`/`parentId` on the
    //   fallback path too, as an integral, `Int32`-range number.

    func testFromJsonFallsBackToLegacyParseWhenAnUndeclaredKeyIsPresent() throws {
        let json = """
            {"viewId": 7, "parentId": 3, "notDeclaredInSchema": "whatever"}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.viewId, 7)
        XCTAssertEqual(data.parentId, 3)
    }

    func testFromJsonThrowsWhenViewIdIsAnInvalidValue() throws {
        let json = """
            {"viewId": 3.5}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonThrowsWhenViewIdIsANumericString() throws {
        let json = """
            {"viewId": "1"}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonThrowsWhenViewIdIsOutsideTheInt32Range() throws {
        // The generated Kotlin type for viewId is Int (32-bit); Android cannot represent
        // 3000000000 at all.
        let json = """
            {"viewId": 3000000000}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonThrowsForAnInvalidViewIdEvenWhenAnUndeclaredKeyIsAlsoPresent() throws {
        let json = """
            {"viewId": 3.5, "notDeclaredInSchema": true}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonThrowsForANumericStringViewIdEvenWhenAnUndeclaredKeyIsAlsoPresent() throws {
        let json = """
            {"viewId": "1", "notDeclaredInSchema": true}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonThrowsForAnOutOfRangeViewIdEvenWhenAnUndeclaredKeyIsAlsoPresent() throws {
        let json = """
            {"viewId": 3000000000, "notDeclaredInSchema": true}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonThrowsWhenViewIdIsABooleanEvenWhenAnUndeclaredKeyIsAlsoPresent() throws {
        // A JSON boolean bridges to NSNumber, so without the CFBoolean check `true` would
        // decode as viewId 1 here while Kotlin's `raw is Number` rejects it.
        let json = """
            {"viewId": true, "notDeclaredInSchema": true}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonAcceptsViewIdZeroOnTheFallbackPath() throws {
        // Guards the boolean check above: Foundation bridges NSNumber 0 and 1 to Bool, so a
        // naive `raw is Bool` test would reject the two most common view ids.
        let json = """
            {"viewId": 0, "notDeclaredInSchema": true}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.viewId, 0)
    }

    func testFromJsonThrowsForANumericStringParentIdEvenWhenAnUndeclaredKeyIsAlsoPresent() throws {
        let json = """
            {"viewId": 1, "parentId": "9", "notDeclaredInSchema": true}
            """

        XCTAssertThrowsError(try DataCaptureViewCreationData.fromJson(json))
    }

    func testFromJsonFallsBackToLegacyParseForAValidParentIdWhenAnUndeclaredKeyTriggersIt() throws {
        let json = """
            {"viewId": 1, "parentId": 9, "notDeclaredInSchema": true}
            """

        let data = try DataCaptureViewCreationData.fromJson(json)

        XCTAssertEqual(data.viewId, 1)
        XCTAssertEqual(data.parentId, 9)
    }
}
