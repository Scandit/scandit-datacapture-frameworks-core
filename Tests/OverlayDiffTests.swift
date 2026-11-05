/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore
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

    // MARK: - Overlay dispatched before its mode exists

    func testOverlayDispatchedBeforeItsModeExistsIsAttachedOnceUnderItsKey() throws {
        try withDeferringModeModule { core, modeModule, view in
            let json = Self.viewJson(("barcodeBatchBasic", 7))

            core.updateDataCaptureView(viewJson: json, result: FakeFrameworksResult())
            core.updateDataCaptureView(viewJson: json, result: FakeFrameworksResult())
            modeModule.addMode(7)

            XCTAssertEqual(modeModule.dispatchCount, 1)
            XCTAssertEqual(view.overlays.count, 1)
            XCTAssertEqual(view.overlayKeys, ["barcodeBatchBasic:7"])
        }
    }

    func testOverlayRemovedBeforeItsModeExistsIsNeverAttached() throws {
        try withDeferringModeModule { core, modeModule, view in
            core.updateDataCaptureView(
                viewJson: Self.viewJson(("barcodeBatchBasic", 7)),
                result: FakeFrameworksResult()
            )
            core.updateDataCaptureView(viewJson: Self.viewJson(), result: FakeFrameworksResult())
            modeModule.addMode(7)

            XCTAssertTrue(view.overlays.isEmpty)
            XCTAssertTrue(view.overlayKeys.isEmpty)
        }
    }

    func testDeferredOverlaysOfTwoModesBindToTheirOwnKeysWhateverOrderTheModesArrive() throws {
        try withDeferringModeModule { core, modeModule, view in
            core.updateDataCaptureView(
                viewJson: Self.viewJson(("barcodeBatchBasic", 7), ("barcodeCapture", 8)),
                result: FakeFrameworksResult()
            )
            modeModule.addMode(8)
            let captureOverlay = try XCTUnwrap(view.overlays.first)
            modeModule.addMode(7)
            core.updateDataCaptureView(
                viewJson: Self.viewJson(("barcodeBatchBasic", 7)),
                result: FakeFrameworksResult()
            )

            XCTAssertEqual(view.overlayKeys, ["barcodeBatchBasic:7"])
            XCTAssertEqual(view.overlays.count, 1)
            XCTAssertFalse(view.overlays.contains { $0 === captureOverlay })
        }
    }

    func testDeferredOverlayReplacedBySameTypeOfAnotherModeIsNeverAttached() throws {
        try withDeferringModeModule { core, modeModule, view in
            core.updateDataCaptureView(
                viewJson: Self.viewJson(("barcodeBatchBasic", 7)),
                result: FakeFrameworksResult()
            )
            core.updateDataCaptureView(
                viewJson: Self.viewJson(("barcodeBatchBasic", 9)),
                result: FakeFrameworksResult()
            )
            modeModule.addMode(7)
            modeModule.addMode(9)

            XCTAssertEqual(view.overlayKeys, ["barcodeBatchBasic:9"])
            XCTAssertEqual(view.overlays.count, 1)
        }
    }

    func testDeferredOverlayIsDroppedByRemoveAllOverlays() throws {
        try withDeferringModeModule { core, modeModule, view in
            core.updateDataCaptureView(
                viewJson: Self.viewJson(("barcodeBatchBasic", 7)),
                result: FakeFrameworksResult()
            )
            view.removeAllOverlays()
            modeModule.addMode(7)

            XCTAssertTrue(view.overlays.isEmpty)
            XCTAssertTrue(view.overlayKeys.isEmpty)
        }
    }

    private static let viewId = 35180

    private static func viewJson(_ overlays: (type: String, modeId: Int)...) -> String {
        let entries = overlays.map { "{\"type\":\"\($0.type)\",\"modeId\":\($0.modeId)}" }
        return "{\"viewId\":\(viewId),\"overlays\":[\(entries.joined(separator: ","))]}"
    }

    private func withDeferringModeModule(
        _ body: (CoreModule, DeferringModeModule, FrameworksDataCaptureView) throws -> Void
    ) throws {
        let core = CoreModule.create(emitter: OverlayDiffNoopEmitter())
        core.didStart()
        let modeModule = DeferringModeModule()
        DeserializationLifeCycleDispatcher.shared.attach(observer: modeModule)
        defer {
            DeserializationLifeCycleDispatcher.shared.detach(observer: modeModule)
            core.didStop()
            ScanditLoggerTestSupport.resetLogger()
            ScanditLoggerTestSupport.drainScheduledFlush(self)
        }

        let contextJson = try Self.contextJson()
        requireSuccess("createContextFromJson") {
            core.createContextFromJson(contextJson: contextJson, result: $0)
        }
        requireSuccess("createDataCaptureView") {
            core.createDataCaptureView(viewJson: "{\"viewId\":\(Self.viewId)}", result: $0) { _ in }
        }
        let view = try XCTUnwrap(DataCaptureViewHandler.shared.getView(Self.viewId))
        defer { DataCaptureViewHandler.shared.removeView(Self.viewId) }

        try body(core, modeModule, view)
    }

    private static func contextJson() throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "license-link", withExtension: "json"))
        let license = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let context: [String: Any] = [
            "licenseKey": try XCTUnwrap(license["key"] as? String),
            "framework": "react-native",
            "frameworkVersion": "0.74.1",
        ]
        return String(decoding: try JSONSerialization.data(withJSONObject: context), as: UTF8.self)
    }

    private func requireSuccess(_ step: String, execute: (FrameworksResult) -> Void) {
        let result = FakeFrameworksResult()
        execute(result)
        let deadline = Date(timeIntervalSinceNow: 5)
        while !result.successCalled && !result.rejectCalled && Date() < deadline {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
        XCTAssertTrue(result.successCalled, "\(step) failed: \(result.rejectMessage ?? "did not settle")")
    }
}

private final class OverlayDiffNoopEmitter: Emitter {
    func emit(name: String, payload: [String: Any?]) {}
    func hasListener(for event: String) -> Bool { false }
    func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool { false }
    func hasModeSpecificListenersForEvent(_ modeId: Int, for event: String) -> Bool { false }
}

/// Mirrors a mode module's overlay attach: while the mode is not cached the attach is deferred
/// through the real post-mode-creation queue and replayed when the mode arrives.
private final class DeferringModeModule: BasicFrameworkModule<String>, DeserializationLifeCycleObserver {
    private(set) var dispatchCount = 0

    func addMode(_ modeId: Int) {
        addModeToCache(modeId: modeId, mode: "mode-\(modeId)")
        getPostModeCreationActions(modeId).forEach { $0() }
    }

    func dataCaptureView(addOverlay overlayJson: String, to view: FrameworksDataCaptureView) throws {
        dispatchCount += 1
        let json = try? JSONSerialization.jsonObject(with: Data(overlayJson.utf8)) as? [String: Any]
        attachOverlay(to: view, modeId: json?["modeId"] as? Int ?? -1)
    }

    private func attachOverlay(to view: FrameworksDataCaptureView, modeId: Int) {
        guard getModeFromCache(modeId) != nil else {
            addPostModeCreationAction(modeId) { [weak self] in self?.attachOverlay(to: view, modeId: modeId) }
            return
        }
        view.addOverlay(ColorFillOverlay(color: .red))
    }
}
