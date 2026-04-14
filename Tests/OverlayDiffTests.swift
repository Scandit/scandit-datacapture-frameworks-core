/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

/// Tests that validate the overlay diff algorithm used in CoreModule.updateDataCaptureView.
///
/// Since FrameworksDataCaptureView requires ScanditCaptureCore types to instantiate,
/// these tests replicate the exact diff logic and verify it produces correct add/remove
/// decisions for every scenario.
final class OverlayDiffTests: XCTestCase {

    /// Represents the result of applying the overlay diff.
    struct DiffResult {
        let keysToRemove: Set<String>
        let keysToAdd: Set<String>
        /// For each key to add, the types that would trigger removeExistingOverlaysOfType.
        let conflictingRemovals: [(type: String, excludingKey: String)]
    }

    /// Replicates the diff logic from CoreModule.updateDataCaptureView.
    private func computeDiff(
        existingKeys: Set<String>,
        incoming: [OverlayEntry]
    ) -> DiffResult {
        let incomingKeys = Set(incoming.map(\.key))

        let keysToRemove = existingKeys.subtracting(incomingKeys)
        let keysToAdd = incomingKeys.subtracting(existingKeys)

        // Simulate what happens: for each entry to add, we check for same-type conflicts
        // among existing keys (after removal of keysToRemove)
        let remainingAfterRemoval = existingKeys.subtracting(keysToRemove)

        var conflictingRemovals: [(type: String, excludingKey: String)] = []
        for entry in incoming where keysToAdd.contains(entry.key) {
            let hasConflict = remainingAfterRemoval.contains { existingKey in
                existingKey != entry.key && existingKey.hasPrefix("\(entry.type):")
            }
            if hasConflict {
                conflictingRemovals.append((type: entry.type, excludingKey: entry.key))
            }
        }

        return DiffResult(
            keysToRemove: keysToRemove,
            keysToAdd: keysToAdd,
            conflictingRemovals: conflictingRemovals
        )
    }

    // MARK: - No change

    func testSameOverlaysResultInNoChanges() {
        let existing: Set<String> = ["labelCapture:1"]
        let incoming = [OverlayEntry(key: "labelCapture:1", type: "labelCapture", jsonString: "{}")]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertTrue(diff.keysToRemove.isEmpty)
        XCTAssertTrue(diff.keysToAdd.isEmpty)
        XCTAssertTrue(diff.conflictingRemovals.isEmpty)
    }

    func testMultipleSameOverlaysResultInNoChanges() {
        let existing: Set<String> = ["labelCapture:1", "barcodeCapture:2"]
        let incoming = [
            OverlayEntry(key: "labelCapture:1", type: "labelCapture", jsonString: "{}"),
            OverlayEntry(key: "barcodeCapture:2", type: "barcodeCapture", jsonString: "{}"),
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertTrue(diff.keysToRemove.isEmpty)
        XCTAssertTrue(diff.keysToAdd.isEmpty)
    }

    // MARK: - Add new overlay

    func testNewOverlayIsAdded() {
        let existing: Set<String> = ["labelCapture:1"]
        let incoming = [
            OverlayEntry(key: "labelCapture:1", type: "labelCapture", jsonString: "{}"),
            OverlayEntry(key: "barcodeCapture:2", type: "barcodeCapture", jsonString: "{}"),
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertTrue(diff.keysToRemove.isEmpty)
        XCTAssertEqual(diff.keysToAdd, ["barcodeCapture:2"])
    }

    func testFirstOverlayAddedToEmptyView() {
        let existing: Set<String> = []
        let incoming = [
            OverlayEntry(key: "labelCapture:1", type: "labelCapture", jsonString: "{}")
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertTrue(diff.keysToRemove.isEmpty)
        XCTAssertEqual(diff.keysToAdd, ["labelCapture:1"])
    }

    // MARK: - Remove overlay

    func testOverlayIsRemovedWhenNotInIncoming() {
        let existing: Set<String> = ["labelCapture:1", "barcodeCapture:2"]
        let incoming = [
            OverlayEntry(key: "labelCapture:1", type: "labelCapture", jsonString: "{}")
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertEqual(diff.keysToRemove, ["barcodeCapture:2"])
        XCTAssertTrue(diff.keysToAdd.isEmpty)
    }

    func testAllOverlaysRemovedWhenIncomingIsEmpty() {
        let existing: Set<String> = ["labelCapture:1", "barcodeCapture:2"]
        let incoming: [OverlayEntry] = []

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertEqual(diff.keysToRemove, ["labelCapture:1", "barcodeCapture:2"])
        XCTAssertTrue(diff.keysToAdd.isEmpty)
    }

    // MARK: - Same type, different modeId (swap)

    func testSameTypeDifferentModeIdTriggersRemoveAndAdd() {
        let existing: Set<String> = ["labelCapture:1"]
        let incoming = [
            OverlayEntry(key: "labelCapture:2", type: "labelCapture", jsonString: "{}")
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertEqual(diff.keysToRemove, ["labelCapture:1"])
        XCTAssertEqual(diff.keysToAdd, ["labelCapture:2"])
    }

    func testModeIdSwapWithOtherTypesUnchanged() {
        let existing: Set<String> = ["labelCapture:1", "barcodeCapture:3"]
        let incoming = [
            OverlayEntry(key: "labelCapture:2", type: "labelCapture", jsonString: "{}"),
            OverlayEntry(key: "barcodeCapture:3", type: "barcodeCapture", jsonString: "{}"),
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertEqual(diff.keysToRemove, ["labelCapture:1"])
        XCTAssertEqual(diff.keysToAdd, ["labelCapture:2"])
    }

    // MARK: - Complete overlay type swap

    func testReplacingOneOverlayTypeWithAnother() {
        let existing: Set<String> = ["labelCapture:1"]
        let incoming = [
            OverlayEntry(key: "barcodeCapture:1", type: "barcodeCapture", jsonString: "{}")
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertEqual(diff.keysToRemove, ["labelCapture:1"])
        XCTAssertEqual(diff.keysToAdd, ["barcodeCapture:1"])
    }

    // MARK: - Same type co-existence prevention

    func testConflictingTypeDetectedWhenAddingOverlayWithExistingType() {
        // Existing: labelCapture:1, barcodeCapture:1
        // Incoming: labelCapture:2, barcodeCapture:1
        // labelCapture:1 is removed by diff, labelCapture:2 is added.
        // Since labelCapture:1 is in keysToRemove, it's already gone before the add,
        // so there should be no conflicting removal needed.
        let existing: Set<String> = ["labelCapture:1", "barcodeCapture:1"]
        let incoming = [
            OverlayEntry(key: "labelCapture:2", type: "labelCapture", jsonString: "{}"),
            OverlayEntry(key: "barcodeCapture:1", type: "barcodeCapture", jsonString: "{}"),
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertEqual(diff.keysToRemove, ["labelCapture:1"])
        XCTAssertEqual(diff.keysToAdd, ["labelCapture:2"])
        // No conflicting removal because labelCapture:1 is already in keysToRemove
        XCTAssertTrue(diff.conflictingRemovals.isEmpty)
    }

    func testConflictingTypeWhenNotRemovedByDiff() {
        // Edge case: existingKeys has labelCapture:1, incoming has both labelCapture:1 AND labelCapture:2
        // labelCapture:1 stays (not in keysToRemove), labelCapture:2 is new (in keysToAdd)
        // removeExistingOverlaysOfType should be triggered to remove labelCapture:1
        let existing: Set<String> = ["labelCapture:1"]
        let incoming = [
            OverlayEntry(key: "labelCapture:1", type: "labelCapture", jsonString: "{}"),
            OverlayEntry(key: "labelCapture:2", type: "labelCapture", jsonString: "{}"),
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertTrue(diff.keysToRemove.isEmpty)
        XCTAssertEqual(diff.keysToAdd, ["labelCapture:2"])
        XCTAssertEqual(diff.conflictingRemovals.count, 1)
        XCTAssertEqual(diff.conflictingRemovals[0].type, "labelCapture")
        XCTAssertEqual(diff.conflictingRemovals[0].excludingKey, "labelCapture:2")
    }

    // MARK: - Empty view

    func testEmptyExistingAndEmptyIncoming() {
        let diff = computeDiff(existingKeys: [], incoming: [])

        XCTAssertTrue(diff.keysToRemove.isEmpty)
        XCTAssertTrue(diff.keysToAdd.isEmpty)
    }

    // MARK: - Multiple adds and removes

    func testMultipleSimultaneousAddsAndRemoves() {
        let existing: Set<String> = ["a:1", "b:2", "c:3"]
        let incoming = [
            OverlayEntry(key: "b:2", type: "b", jsonString: "{}"),
            OverlayEntry(key: "d:4", type: "d", jsonString: "{}"),
            OverlayEntry(key: "e:5", type: "e", jsonString: "{}"),
        ]

        let diff = computeDiff(existingKeys: existing, incoming: incoming)

        XCTAssertEqual(diff.keysToRemove, ["a:1", "c:3"])
        XCTAssertEqual(diff.keysToAdd, ["d:4", "e:5"])
    }
}
