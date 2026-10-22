/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import UIKit

public class DefaultAdvancedOverlayViewCache: AdvancedOverlayViewCache {
    private var views: ConcurrentDictionary<String, UIView> = ConcurrentDictionary()

    public init() {}

    public func addToCache(viewIdentifier: String, view: UIView) {
        self.views.setValue(view, for: viewIdentifier)
    }

    public func getView(viewIdentifier: String) -> UIView? {
        views.getValue(for: viewIdentifier)
    }

    public func getOrCreateView(fromImage image: UIImage, withIdentifier viewIdentifier: String) -> UIImageView? {
        var imageView: UIImageView
        if let existingView = views.getValue(for: viewIdentifier) as? UIImageView {
            imageView = existingView
            imageView.image = image
        } else {
            imageView = self.createImageView(with: image, viewIdentifier: viewIdentifier)
        }
        return imageView
    }

    public func getOrCreateView(fromBase64EncodedData data: Data, withIdentifier viewIdentifier: String) -> UIImageView?
    {
        guard let image = parse(data: data) else { return nil }
        return getOrCreateView(fromImage: image, withIdentifier: viewIdentifier)
    }

    public func removeView(withIdentifier viewIdentifier: String) {
        _ = views.removeValue(for: viewIdentifier)
    }

    public func clear() {
        views.removeAllValues()
    }

    private func createImageView(with image: UIImage, viewIdentifier: String) -> UIImageView {
        let imageView = UIImageView(image: image)
        let scale = Self.displayScale()
        imageView.frame.size = CGSize(
            width: imageView.frame.size.width / scale,
            height: imageView.frame.size.height / scale
        )
        views.setValue(imageView, for: viewIdentifier)
        return imageView
    }

    // An unspecified trait scale is 0; fall back to the active scene's screen, not to 1.
    static func displayScale(
        traitScale: CGFloat = UITraitCollection.current.displayScale,
        screenScale: () -> CGFloat? = activeScreenScale
    ) -> CGFloat {
        if traitScale > 0 { return traitScale }
        return screenScale() ?? 1
    }

    static func activeScreenScale() -> CGFloat? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return scene?.screen.scale
    }

    private func parse(data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}
