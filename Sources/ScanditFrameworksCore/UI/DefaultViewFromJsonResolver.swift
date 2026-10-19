/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import UIKit

public class DefaultViewFromJsonResolver: ViewFromJsonResolver {
    public init() {}

    public func getView(viewJson: String?) -> UIView? {
        TappableBase64ImageView(viewJson: viewJson)
    }

    public func getViewFromBytes(
        advancedOverlayViewPool: AdvancedOverlayViewCache,
        viewIdentifier: String,
        viewBytes: Data?
    ) -> UIView? {
        guard let viewBytes = viewBytes else {
            return nil
        }
        return advancedOverlayViewPool.getOrCreateView(
            fromBase64EncodedData: viewBytes,
            withIdentifier: viewIdentifier
        )
    }
}
