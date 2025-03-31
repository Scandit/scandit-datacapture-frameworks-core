/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import UIKit

public protocol AdvancedOverlayViewCache {
    func getOrCreateView(fromImage image: UIImage, withIdentifier viewIdentifier: String) -> UIImageView?
    func getOrCreateView(fromBase64EncodedData data: Data, withIdentifier viewIdentifier: String) -> UIImageView?
    func removeView(withIdentifier viewIdentifier: String)
    func clear()
}
