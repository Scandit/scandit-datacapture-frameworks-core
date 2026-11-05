/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class ListenerRegistryTests: XCTestCase {
    private final class RecordingEmitter: Emitter {
        var emitted: [(String, [String: Any?])] = []
        func emit(name: String, payload: [String: Any?]) { emitted.append((name, payload)) }
        var platformHasListeners = false
        func hasListener(for event: String) -> Bool { platformHasListeners }
        func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool { platformHasListeners }
        func hasModeSpecificListenersForEvent(_ modeId: Int, for event: String) -> Bool { platformHasListeners }
    }

    private let didScan = "BarcodeCaptureListener.didScan"
    private let sizeChanged = "DataCaptureViewListener.onSizeChanged"
    private let stateChanged = "FrameSourceListener.onStateChanged"

    private var registry: ListenerRegistry!
    private var attached: [ListenerTarget] = []
    private var detached: [ListenerTarget] = []
    private var modeAttachment: ListenerAttachment!

    override func setUp() {
        super.setUp()
        registry = ListenerRegistry.shared
        registry.reset()
        attached = []
        detached = []
        modeAttachment = ModuleListenerAttachment.forMode(
            [didScan],
            attach: { [unowned self] in attached.append(.mode($0)) },
            detach: { [unowned self] in detached.append(.mode($0)) }
        )
    }

    override func tearDown() {
        registry.unregister(attachment: modeAttachment)
        registry.reset()
        super.tearDown()
    }

    func testAttachesOncePerTargetAndDetachesOnceOnRemoval() {
        registry.register(attachment: modeAttachment)

        registry.addListener(eventName: didScan, target: .mode(1))
        registry.addListener(eventName: didScan, target: .mode(1))
        registry.addListener(eventName: didScan, target: .mode(2))
        XCTAssertEqual(attached, [.mode(1), .mode(2)])

        registry.removeListener(eventName: didScan, target: .mode(1))
        registry.removeListener(eventName: didScan, target: .mode(1))
        XCTAssertEqual(detached, [.mode(1)])
        XCTAssertFalse(registry.hasListeners(eventName: didScan, target: .mode(1)))
        XCTAssertTrue(registry.hasListeners(eventName: didScan, target: .mode(2)))
    }

    func testUnregisterAttachmentDetachesTargetsStillAttached() {
        registry.register(attachment: modeAttachment)
        registry.addListener(eventName: didScan, target: .mode(3))
        registry.addListener(eventName: didScan, target: .mode(4))

        registry.unregister(attachment: modeAttachment)

        XCTAssertEqual(Set(detached), Set([ListenerTarget.mode(3), ListenerTarget.mode(4)]))
    }

    func testAttachmentRegisteredAfterListenersAttachesExistingTargets() {
        registry.addListener(eventName: didScan, target: .mode(7))

        registry.register(attachment: modeAttachment)

        XCTAssertEqual(attached, [.mode(7)])
    }

    func testMultiEventAttachmentAttachesOncePerTargetAndDetachesAfterLastEvent() {
        let focus = "FocusGestureListener.onFocusGesture"
        let multi = ModuleListenerAttachment.forView(
            [sizeChanged, focus],
            attach: { [unowned self] in attached.append(.view($0)) },
            detach: { [unowned self] in detached.append(.view($0)) }
        )
        registry.register(attachment: multi)
        defer { registry.unregister(attachment: multi) }

        registry.addListener(eventName: sizeChanged, target: .view(3))
        registry.addListener(eventName: focus, target: .view(3))
        XCTAssertEqual(attached, [.view(3)])

        registry.removeListener(eventName: sizeChanged, target: .view(3))
        XCTAssertTrue(detached.isEmpty)

        registry.removeListener(eventName: focus, target: .view(3))
        XCTAssertEqual(detached, [.view(3)])
    }

    func testRemoveAllListenersDetachesMultiEventAttachmentOnce() {
        let focus = "FocusGestureListener.onFocusGesture"
        let multi = ModuleListenerAttachment.forView(
            [sizeChanged, focus],
            attach: { [unowned self] in attached.append(.view($0)) },
            detach: { [unowned self] in detached.append(.view($0)) }
        )
        registry.register(attachment: multi)
        defer { registry.unregister(attachment: multi) }
        registry.addListener(eventName: sizeChanged, target: .view(5))
        registry.addListener(eventName: focus, target: .view(5))

        registry.removeAllListeners(target: .view(5))

        XCTAssertEqual(detached, [.view(5)])
    }

    func testViewAndModeTargetsWithSameIdAreDistinct() {
        registry.addListener(eventName: sizeChanged, target: .view(3))

        XCTAssertTrue(registry.hasListeners(eventName: sizeChanged, target: .view(3)))
        XCTAssertFalse(registry.hasListeners(eventName: sizeChanged, target: .mode(3)))
        XCTAssertTrue(registry.hasListeners(eventName: sizeChanged))
        XCTAssertFalse(registry.hasListeners(eventName: didScan))
    }

    func testModeAttachmentIgnoresViewAndGlobalTargets() {
        registry.register(attachment: modeAttachment)

        registry.addListener(eventName: didScan, target: .view(1))
        registry.addListener(eventName: didScan, target: .global)

        XCTAssertTrue(attached.isEmpty)
    }

    func testRegistryEmitterForwardsPayloadsAndReportsListenersFromRegistryOrPlatform() {
        let emitter = RecordingEmitter()
        let registryEmitter = RegistryEmitter(platformEmitter: emitter, registry: registry)
        registry.addListener(eventName: didScan, target: .mode(5))

        registryEmitter.emit(name: didScan, payload: ["modeId": 6])
        XCTAssertEqual(emitter.emitted.count, 1)

        XCTAssertTrue(registryEmitter.hasListener(for: didScan))
        XCTAssertTrue(registryEmitter.hasModeSpecificListenersForEvent(5, for: didScan))
        XCTAssertFalse(registryEmitter.hasModeSpecificListenersForEvent(6, for: didScan))
        XCTAssertFalse(registryEmitter.hasListener(for: stateChanged))
        emitter.platformHasListeners = true
        XCTAssertTrue(registryEmitter.hasModeSpecificListenersForEvent(6, for: didScan))
        XCTAssertTrue(registryEmitter.hasListener(for: stateChanged))
    }

    func testRegistryEmitterForwardsIdLessPayloadsToGlobalListeners() {
        let emitter = RecordingEmitter()
        let registryEmitter = RegistryEmitter(platformEmitter: emitter, registry: registry)
        registry.addListener(eventName: stateChanged, target: .global)

        registryEmitter.emit(name: stateChanged, payload: ["state": "on"])

        XCTAssertEqual(emitter.emitted.count, 1)
    }

    func testRegistryEmitterRoutesIdLessPayloadOfTargetedListenerToCore() {
        let platform = RecordingEmitter()
        let core = RecordingEmitter()
        let previousCore = CoreEventEmitter.emitter
        CoreEventEmitter.emitter = core
        defer { CoreEventEmitter.emitter = previousCore }
        let registryEmitter = RegistryEmitter(platformEmitter: platform, registry: registry)
        registry.addListener(eventName: sizeChanged, target: .view(4))

        registryEmitter.emit(name: sizeChanged, payload: ["width": 1])

        XCTAssertEqual(core.emitted.count, 1)
        XCTAssertTrue(platform.emitted.isEmpty)
    }

    func testRegistryEmitterKeepsPayloadForUnregisteredTargetOnPlatform() {
        let platform = RecordingEmitter()
        let core = RecordingEmitter()
        let previousCore = CoreEventEmitter.emitter
        CoreEventEmitter.emitter = core
        defer { CoreEventEmitter.emitter = previousCore }
        let registryEmitter = RegistryEmitter(platformEmitter: platform, registry: registry)
        registry.addListener(eventName: didScan, target: .mode(5))

        registryEmitter.emit(name: didScan, payload: ["modeId": 6])

        XCTAssertTrue(core.emitted.isEmpty)
        XCTAssertEqual(platform.emitted.count, 1)
    }

    func testRemoveAllListenersDetachesEveryEventOfTarget() {
        let viewAttachment = ModuleListenerAttachment.forView(
            [sizeChanged, "FocusGestureListener.onFocusGesture"],
            attach: { [unowned self] in attached.append(.view($0)) },
            detach: { [unowned self] in detached.append(.view($0)) }
        )
        registry.register(attachment: viewAttachment)
        defer { registry.unregister(attachment: viewAttachment) }
        registry.addListener(eventName: sizeChanged, target: .view(9))
        registry.addListener(eventName: "FocusGestureListener.onFocusGesture", target: .view(9))

        registry.removeAllListeners(target: .view(9))

        XCTAssertEqual(detached, [.view(9)])
        XCTAssertFalse(registry.hasListeners(eventName: sizeChanged))
    }

    func testRemovingUnknownListenerIsNoOp() {
        registry.register(attachment: modeAttachment)

        registry.removeListener(eventName: didScan, target: .mode(1))

        XCTAssertTrue(detached.isEmpty)
    }
}
