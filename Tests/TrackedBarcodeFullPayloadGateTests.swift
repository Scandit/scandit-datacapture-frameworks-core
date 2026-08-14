/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class TrackedBarcodeFullPayloadGateTests: XCTestCase {
    func testFirstCallForAnIdentifierEmitsFull() {
        let sut = TrackedBarcodeFullPayloadGate()

        XCTAssertTrue(sut.shouldEmitFull(identifier: 1))
    }

    func testRepeatCallsForTheSameIdentifierDoNotEmitFull() {
        let sut = TrackedBarcodeFullPayloadGate()

        XCTAssertTrue(sut.shouldEmitFull(identifier: 1))
        XCTAssertFalse(sut.shouldEmitFull(identifier: 1))
        XCTAssertFalse(sut.shouldEmitFull(identifier: 1))
    }

    func testDifferentIdentifiersAreTrackedIndependently() {
        let sut = TrackedBarcodeFullPayloadGate()

        XCTAssertTrue(sut.shouldEmitFull(identifier: 1))
        XCTAssertTrue(sut.shouldEmitFull(identifier: 2))
        XCTAssertFalse(sut.shouldEmitFull(identifier: 1))
        XCTAssertFalse(sut.shouldEmitFull(identifier: 2))
    }

    func testResetClearsAllRecordedIdentifiers() {
        let sut = TrackedBarcodeFullPayloadGate()

        XCTAssertTrue(sut.shouldEmitFull(identifier: 1))
        XCTAssertFalse(sut.shouldEmitFull(identifier: 1))

        sut.reset()

        XCTAssertTrue(sut.shouldEmitFull(identifier: 1))
    }

    func testIdentifiersBeyondMaxSizeEvictTheLeastRecentlyUsedEntry() {
        let sut = TrackedBarcodeFullPayloadGate(maxSize: 2)

        XCTAssertTrue(sut.shouldEmitFull(identifier: 1))
        XCTAssertTrue(sut.shouldEmitFull(identifier: 2))
        // Touching identifier 1 again makes identifier 2 the least-recently-used entry.
        XCTAssertFalse(sut.shouldEmitFull(identifier: 1))

        // A third, brand-new identifier evicts identifier 2 (the least-recently-used entry),
        // not identifier 1 (touched more recently in the line above).
        XCTAssertTrue(sut.shouldEmitFull(identifier: 3))

        // identifier 1 survived the eviction.
        XCTAssertFalse(sut.shouldEmitFull(identifier: 1))
    }
}
