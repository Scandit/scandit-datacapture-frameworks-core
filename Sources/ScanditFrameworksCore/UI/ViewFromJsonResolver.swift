/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import UIKit

public protocol ViewFromJsonResolver {
    func getView(viewJson: String?) -> UIView?

    func getViewFromBytes(
        advancedOverlayViewPool: AdvancedOverlayViewCache,
        viewIdentifier: String,
        viewBytes: Data?
    ) -> UIView?
}
