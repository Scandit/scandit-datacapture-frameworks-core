/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

/// Tests for the overlay diff logic exercised by CoreModule.updateDataCaptureView.
///
/// Since CoreModule.updateDataCaptureView requires a fully initialized FrameworksDataCaptureView
/// (which depends on ScanditCaptureCore binary types), these tests replicate the exact
/// JSON-to-diff pipeline: parse the JSON via DataCaptureViewCreationData, then apply the
/// same diff algorithm used in updateDataCaptureView to verify correct add/remove decisions.
final class UpdateDataCaptureViewTests: XCTestCase {

    /// Represents the overlay state tracked by the view.
    struct OverlayState {
        var keys: Set<String> = []
    }

    /// Represents the result of applying updateDataCaptureView's diff logic.
    struct UpdateResult {
        let removedKeys: Set<String>
        let addedKeys: Set<String>
        /// Entries for which removeExistingOverlaysOfType would be called.
        let conflictTypeRemovals: [(type: String, excludingKey: String)]
    }

    /// Replicates the diff logic from CoreModule.updateDataCaptureView exactly as implemented.
    ///
    /// - Parameters:
    ///   - existingState: Current overlay keys on the view.
    ///   - updateJson: The JSON string that would be passed to updateDataCaptureView.
    /// - Returns: The diff result and updated state.
    private func applyUpdate(
        existingState: inout OverlayState,
        updateJson: String
    ) -> UpdateResult {
        let updateData = DataCaptureViewCreationData.fromJson(updateJson)

        let incomingKeys = Set(updateData.overlays.map(\.key))
        let existingKeys = existingState.keys

        // Step 1: Remove overlays not in incoming
        let keysToRemove = existingKeys.subtracting(incomingKeys)
        for key in keysToRemove {
            existingState.keys.remove(key)
        }

        // Step 2: Add overlays not in existing
        let keysToAdd = incomingKeys.subtracting(existingKeys)
        var conflictTypeRemovals: [(type: String, excludingKey: String)] = []

        for entry in updateData.overlays where keysToAdd.contains(entry.key) {
            // Check for same-type conflicts (removeExistingOverlaysOfType)
            let conflictingKeys = existingState.keys.filter { existingKey in
                existingKey != entry.key && existingKey.hasPrefix("\(entry.type):")
            }
            if !conflictingKeys.isEmpty {
                conflictTypeRemovals.append((type: entry.type, excludingKey: entry.key))
                for conflictKey in conflictingKeys {
                    existingState.keys.remove(conflictKey)
                }
            }

            existingState.keys.insert(entry.key)
        }

        return UpdateResult(
            removedKeys: keysToRemove,
            addedKeys: keysToAdd,
            conflictTypeRemovals: conflictTypeRemovals
        )
    }

    private func buildViewJson(viewId: Int, overlays: [(type: String, modeId: Int)]) -> String {
        let overlayJsons = overlays.map { (type, modeId) in
            "{\"type\":\"\(type)\",\"modeId\":\(modeId)}"
        }.joined(separator: ",")
        return "{\"viewId\":\(viewId),\"overlays\":[\(overlayJsons)]}"
    }

    // MARK: - No overlay change

    func testUpdateWithSameOverlaysResultsInNoChanges() {
        var state = OverlayState(keys: ["labelCapture:1"])

        let json = buildViewJson(viewId: 1, overlays: [("labelCapture", 1)])
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertTrue(result.addedKeys.isEmpty)
        XCTAssertEqual(state.keys, ["labelCapture:1"])
    }

    func testUpdateWithMultipleSameOverlaysResultsInNoChanges() {
        var state = OverlayState(keys: ["labelCapture:1", "barcodeCapture:2"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("labelCapture", 1), ("barcodeCapture", 2),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertTrue(result.addedKeys.isEmpty)
        XCTAssertEqual(state.keys, ["labelCapture:1", "barcodeCapture:2"])
    }

    // MARK: - Add new overlay

    func testUpdateAddsNewOverlayWhileKeepingExisting() {
        var state = OverlayState(keys: ["labelCapture:1"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("labelCapture", 1), ("barcodeCapture", 2),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertEqual(result.addedKeys, ["barcodeCapture:2"])
        XCTAssertEqual(state.keys, ["labelCapture:1", "barcodeCapture:2"])
    }

    func testUpdateAddsFirstOverlayToEmptyView() {
        var state = OverlayState()

        let json = buildViewJson(viewId: 1, overlays: [("labelCapture", 1)])
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertEqual(result.addedKeys, ["labelCapture:1"])
        XCTAssertEqual(state.keys, ["labelCapture:1"])
    }

    func testUpdateAddsMultipleNewOverlaysToEmptyView() {
        var state = OverlayState()

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("labelCapture", 1), ("barcodeCapture", 2),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.addedKeys, ["labelCapture:1", "barcodeCapture:2"])
        XCTAssertEqual(state.keys, ["labelCapture:1", "barcodeCapture:2"])
    }

    // MARK: - Remove overlay

    func testUpdateRemovesOverlayWhenNotInIncoming() {
        var state = OverlayState(keys: ["labelCapture:1", "barcodeCapture:2"])

        let json = buildViewJson(viewId: 1, overlays: [("labelCapture", 1)])
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["barcodeCapture:2"])
        XCTAssertTrue(result.addedKeys.isEmpty)
        XCTAssertEqual(state.keys, ["labelCapture:1"])
    }

    func testUpdateRemovesAllOverlaysWhenIncomingIsEmpty() {
        var state = OverlayState(keys: ["labelCapture:1", "barcodeCapture:2"])

        let json = "{\"viewId\":1,\"overlays\":[]}"
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["labelCapture:1", "barcodeCapture:2"])
        XCTAssertTrue(result.addedKeys.isEmpty)
        XCTAssertTrue(state.keys.isEmpty)
    }

    func testUpdateRemovesAllOverlaysWhenOverlaysKeyIsAbsent() {
        var state = OverlayState(keys: ["labelCapture:1"])

        let json = "{\"viewId\":1}"
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["labelCapture:1"])
        XCTAssertTrue(state.keys.isEmpty)
    }

    // MARK: - Same type, different modeId (swap)

    func testUpdateReplacesOverlayWhenSameTypeDifferentModeId() {
        var state = OverlayState(keys: ["labelCapture:1"])

        let json = buildViewJson(viewId: 1, overlays: [("labelCapture", 2)])
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["labelCapture:1"])
        XCTAssertEqual(result.addedKeys, ["labelCapture:2"])
        XCTAssertEqual(state.keys, ["labelCapture:2"])
    }

    func testUpdateSwapsModeIdWhileKeepingOtherTypes() {
        var state = OverlayState(keys: ["labelCapture:1", "barcodeCapture:3"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("labelCapture", 2), ("barcodeCapture", 3),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["labelCapture:1"])
        XCTAssertEqual(result.addedKeys, ["labelCapture:2"])
        XCTAssertEqual(state.keys, ["labelCapture:2", "barcodeCapture:3"])
    }

    // MARK: - Complete overlay type swap

    func testUpdateReplacesOneOverlayTypeWithAnother() {
        var state = OverlayState(keys: ["labelCapture:1"])

        let json = buildViewJson(viewId: 1, overlays: [("barcodeCapture", 1)])
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["labelCapture:1"])
        XCTAssertEqual(result.addedKeys, ["barcodeCapture:1"])
        XCTAssertEqual(state.keys, ["barcodeCapture:1"])
    }

    func testUpdateSwapsAllOverlayTypes() {
        var state = OverlayState(keys: ["labelCapture:1", "barcodeCapture:2"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("idCapture", 3), ("textCapture", 4),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["labelCapture:1", "barcodeCapture:2"])
        XCTAssertEqual(result.addedKeys, ["idCapture:3", "textCapture:4"])
        XCTAssertEqual(state.keys, ["idCapture:3", "textCapture:4"])
    }

    // MARK: - Same type co-existence prevention

    func testUpdateRemovesConflictingTypeWhenNewModeIdAdded() {
        // Existing: labelCapture:1 and barcodeCapture:1
        // Incoming: labelCapture:2 and barcodeCapture:1
        // labelCapture:1 removed by diff, labelCapture:2 added
        var state = OverlayState(keys: ["labelCapture:1", "barcodeCapture:1"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("labelCapture", 2), ("barcodeCapture", 1),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["labelCapture:1"])
        XCTAssertEqual(result.addedKeys, ["labelCapture:2"])
        // No conflicting removal needed since labelCapture:1 was already removed by diff
        XCTAssertTrue(result.conflictTypeRemovals.isEmpty)
    }

    func testUpdateDetectsConflictWhenBothOldAndNewSameTypeExist() {
        // Edge case: existing has labelCapture:1, incoming has both labelCapture:1 AND labelCapture:2
        // labelCapture:1 stays, labelCapture:2 is added
        // removeExistingOverlaysOfType triggered because labelCapture:1 still exists
        var state = OverlayState(keys: ["labelCapture:1"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("labelCapture", 1), ("labelCapture", 2),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertEqual(result.addedKeys, ["labelCapture:2"])
        XCTAssertEqual(result.conflictTypeRemovals.count, 1)
        XCTAssertEqual(result.conflictTypeRemovals[0].type, "labelCapture")
        XCTAssertEqual(result.conflictTypeRemovals[0].excludingKey, "labelCapture:2")
    }

    // MARK: - Empty view

    func testUpdateOnEmptyViewWithEmptyIncoming() {
        var state = OverlayState()

        let json = "{\"viewId\":1,\"overlays\":[]}"
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertTrue(result.addedKeys.isEmpty)
        XCTAssertTrue(state.keys.isEmpty)
    }

    // MARK: - Multiple simultaneous adds and removes

    func testUpdateWithMultipleAddsAndRemoves() {
        var state = OverlayState(keys: ["a:1", "b:2", "c:3"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("b", 2), ("d", 4), ("e", 5),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["a:1", "c:3"])
        XCTAssertEqual(result.addedKeys, ["d:4", "e:5"])
        XCTAssertEqual(state.keys, ["b:2", "d:4", "e:5"])
    }

    // MARK: - Idempotent updates

    func testCallingUpdateTwiceWithSameJsonIsIdempotent() {
        var state = OverlayState()

        let json = buildViewJson(viewId: 1, overlays: [("labelCapture", 1)])

        // First update
        _ = applyUpdate(existingState: &state, updateJson: json)
        XCTAssertEqual(state.keys, ["labelCapture:1"])

        // Second update with same JSON
        let result = applyUpdate(existingState: &state, updateJson: json)
        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertTrue(result.addedKeys.isEmpty)
        XCTAssertEqual(state.keys, ["labelCapture:1"])
    }

    // MARK: - Sequential updates with changing overlays

    func testSequentialUpdatesCorrectlyTrackOverlayState() {
        var state = OverlayState()

        // 1. Add labelCapture:1
        var json = buildViewJson(viewId: 1, overlays: [("labelCapture", 1)])
        _ = applyUpdate(existingState: &state, updateJson: json)
        XCTAssertEqual(state.keys, ["labelCapture:1"])

        // 2. Swap to labelCapture:2
        json = buildViewJson(viewId: 1, overlays: [("labelCapture", 2)])
        _ = applyUpdate(existingState: &state, updateJson: json)
        XCTAssertEqual(state.keys, ["labelCapture:2"])

        // 3. Add barcodeCapture:3
        json = buildViewJson(
            viewId: 1,
            overlays: [
                ("labelCapture", 2), ("barcodeCapture", 3),
            ]
        )
        _ = applyUpdate(existingState: &state, updateJson: json)
        XCTAssertEqual(state.keys, ["labelCapture:2", "barcodeCapture:3"])

        // 4. Remove all
        json = "{\"viewId\":1,\"overlays\":[]}"
        _ = applyUpdate(existingState: &state, updateJson: json)
        XCTAssertTrue(state.keys.isEmpty)
    }

    // MARK: - JSON parsing integration

    func testUpdateJsonWithExtraFieldsInOverlayDoesNotAffectDiff() {
        var state = OverlayState(keys: ["labelCapture:1"])

        let json = """
            {"viewId":1,"overlays":[{"type":"labelCapture","modeId":1,"brush":{"fill":"#FF0000"},"visible":true}]}
            """
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertTrue(result.removedKeys.isEmpty)
        XCTAssertTrue(result.addedKeys.isEmpty)
        XCTAssertEqual(state.keys, ["labelCapture:1"])
    }

    func testUpdateJsonWithMissingModeIdUsesDefault() {
        var state = OverlayState()

        let json = """
            {"viewId":1,"overlays":[{"type":"labelCapture"}]}
            """
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.addedKeys, ["labelCapture:-1"])
        XCTAssertEqual(state.keys, ["labelCapture:-1"])
    }

    func testUpdateJsonSkipsOverlaysWithoutType() {
        var state = OverlayState()

        let json = """
            {"viewId":1,"overlays":[{"type":"labelCapture","modeId":1},{"modeId":2}]}
            """
        let result = applyUpdate(existingState: &state, updateJson: json)

        // Only the valid overlay should be added
        XCTAssertEqual(result.addedKeys, ["labelCapture:1"])
        XCTAssertEqual(state.keys, ["labelCapture:1"])
    }

    // MARK: - Three-way swap scenario

    func testThreeOverlayTypeRotation() {
        // a:1, b:2, c:3 → b:2, c:4, d:5
        var state = OverlayState(keys: ["a:1", "b:2", "c:3"])

        let json = buildViewJson(
            viewId: 1,
            overlays: [
                ("b", 2), ("c", 4), ("d", 5),
            ]
        )
        let result = applyUpdate(existingState: &state, updateJson: json)

        XCTAssertEqual(result.removedKeys, ["a:1", "c:3"])
        XCTAssertEqual(result.addedKeys, ["c:4", "d:5"])
        XCTAssertEqual(state.keys, ["b:2", "c:4", "d:5"])
    }
}
