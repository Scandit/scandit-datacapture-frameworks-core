/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

final class OverlayDispatchScope {
    // Main-confined: overlay dispatch and mode-module attach both run on the main thread.
    static var current: OverlayDispatchScope?

    let view: FrameworksDataCaptureView
    let key: String

    init(view: FrameworksDataCaptureView, key: String) {
        self.view = view
        self.key = key
    }
}
