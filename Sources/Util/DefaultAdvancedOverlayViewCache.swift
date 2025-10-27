/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import UIKit

public class DefaultAdvancedOverlayViewCache: AdvancedOverlayViewCache {
    private var views: [String: UIImageView] = [:]
    private let lock = NSLock()

    public init() {}

    public func getOrCreateView(fromImage image: UIImage, withIdentifier viewIdentifier: String) -> UIImageView? {
        var imageView: UIImageView
        if self.views.keys.contains(viewIdentifier) {
            imageView = self.views[viewIdentifier]!
            imageView.image = image
        } else {
            imageView = self.createImageView(with: image, viewIdentifier:  viewIdentifier)
        }
        return imageView
    }

    public func getOrCreateView(fromBase64EncodedData data: Data, withIdentifier viewIdentifier: String) -> UIImageView? {
        guard let image = parse(data: data) else { return nil }
        return getOrCreateView(fromImage: image, withIdentifier: viewIdentifier)
    }

    public func removeView(withIdentifier viewIdentifier: String) {
        dispatchMain {
            self.views.removeValue(forKey: viewIdentifier)
        }
    }

    public func clear() {
        dispatchMain {
            self.views.removeAll()
        }
    }

    private func createImageView(with image: UIImage, viewIdentifier: String) -> UIImageView {
        let imageView = UIImageView(image: image)
        let scale = UIScreen.main.scale
        imageView.frame.size = CGSize(width: imageView.frame.size.width / scale,
                                      height: imageView.frame.size.height / scale)
        self.views[viewIdentifier] = imageView
        return imageView
    }

    private func parse(data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}
