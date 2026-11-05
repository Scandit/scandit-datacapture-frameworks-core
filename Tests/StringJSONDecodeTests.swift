/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation
import XCTest

@testable import ScanditFrameworksCore

// Regression coverage for SDC-30555: a native result object was placed raw into an event payload,
// which made the emitter's JSONSerialization abort. `decodeJSONObject()` turns the native
// `jsonString` into a valid JSON dictionary instead.
final class StringJSONDecodeTests: XCTestCase {

    private func receiptJSON(storeName: String = "ACME", paymentTotal: Double = 12.5) -> String {
        """
        {
            "storeName": "\(storeName)",
            "date": "2026-04-03",
            "paymentTotal": \(paymentTotal),
            "loyaltyNumber": 42,
            "lineItems": [{"name": "milk", "quantity": 2}]
        }
        """
    }

    func testDecodeJSONObject_returnsNonNilForValidJSON() {
        XCTAssertNotNil(receiptJSON().decodeJSONObject())
    }

    func testDecodeJSONObject_returnsNilForEmptyString() {
        XCTAssertNil("".decodeJSONObject())
    }

    func testDecodeJSONObject_returnsNilForMalformedJSON() {
        XCTAssertNil("not json {{{".decodeJSONObject())
    }

    func testDecodeJSONObject_returnsNilForBareNumber() {
        XCTAssertNil("42".decodeJSONObject())
    }

    func testDecodeJSONObject_returnsNilForJSONArray() {
        XCTAssertNil("[1, 2, 3]".decodeJSONObject())
    }

    func testDecodeJSONObject_parsesValues() throws {
        let dict = try XCTUnwrap(receiptJSON().decodeJSONObject())
        XCTAssertEqual(dict["storeName"] as? String, "ACME")
        XCTAssertEqual(dict["paymentTotal"] as? Double, 12.5)
        XCTAssertNotNil(dict["lineItems"] as? [[String: Any]])
    }

    // The decoded object, wrapped as the emitter would wrap it, must be JSON-serializable — this is
    // exactly the condition that aborted when the raw native result object was emitted instead.
    func testDecodedPayload_isJSONSerializable() throws {
        let dict = try XCTUnwrap(receiptJSON().decodeJSONObject())
        let payload: [String: Any] = ["result": dict]
        XCTAssertTrue(JSONSerialization.isValidJSONObject(payload))
        XCTAssertNoThrow(try JSONSerialization.data(withJSONObject: payload))
    }

    // Documents the pre-fix failure mode: a raw NSObject in the payload is not a valid JSON object.
    func testRawObjectPayload_isNotJSONSerializable() {
        XCTAssertFalse(JSONSerialization.isValidJSONObject(["result": NSObject()]))
    }

    // Round-trips with the existing inverse helper.
    func testEncodeThenDecode_roundTrips() throws {
        let original: [String: Any] = ["storeName": "ACME", "paymentTotal": 12.5]
        let json = try XCTUnwrap(original.encodeToJSONString())
        let decoded = try XCTUnwrap(json.decodeJSONObject())
        XCTAssertEqual(decoded["storeName"] as? String, "ACME")
        XCTAssertEqual(decoded["paymentTotal"] as? Double, 12.5)
    }
}
