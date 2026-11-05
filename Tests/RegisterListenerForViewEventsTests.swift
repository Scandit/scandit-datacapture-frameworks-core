/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

/// Regression coverage for SDC-32821: registering a view listener before the
/// native view exists in DataCaptureViewHandler's cache used to silently
/// no-op while still reporting success, so JS believed it registered and no
/// event ever fired.
///
/// A real FrameworksDataCaptureView can't be constructed in a unit test (it
/// requires a live DataCaptureContext / native view deserialization), so this
/// verifies the fix at the retry-queue boundary: registering against an
/// unknown viewId must defer via addPostSpecificViewCreationAction (as the
/// sibling gesture-listener methods already do) instead of completing
/// immediately with no way to retry once the view is created.
private class SpyFrameworksResult: FrameworksResult {
    private(set) var successCallCount = 0
    private(set) var successAndKeepCallbackCallCount = 0

    func success(result: Any?) {
        successCallCount += 1
    }

    func successAndKeepCallback(result: Any?) {
        successAndKeepCallbackCallCount += 1
    }

    func reject(code: String, message: String?, details: Any?) {}
    func reject(error: Error) {}
}

private class NoopEmitter: Emitter {
    func emit(name: String, payload: [String: Any?]) {}
    func hasListener(for event: String) -> Bool { false }
    func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool { false }
    func hasModeSpecificListenersForEvent(_ modeId: Int, for event: String) -> Bool { false }
}

final class RegisterListenerForViewEventsTests: XCTestCase {

    func testRegisterListenerForViewEventsBeforeViewExistsQueuesRetryInsteadOfReportingSuccess() {
        let coreModule = CoreModule.create(emitter: NoopEmitter())
        // Use a viewId that is guaranteed not to be in the shared, process-wide
        // DataCaptureViewHandler cache.
        let viewId = Int.max - 12345
        let result = SpyFrameworksResult()

        coreModule.registerListenerForViewEvents(viewId: viewId, result: result)

        // The bug: success was reported unconditionally even though no
        // listener was attached and nothing was queued to retry once the
        // view is created.
        XCTAssertEqual(
            result.successCallCount,
            0,
            "must not report success before the view exists and the listener is actually attached"
        )

        let queuedActions = coreModule.getPostSpecificViewCreationActions(viewId: viewId)
        XCTAssertEqual(
            queuedActions.count,
            1,
            "must queue exactly one retry action via addPostSpecificViewCreationAction, "
                + "matching registerFocusGestureListener/registerZoomGestureListener"
        )
    }
}
