/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public final class DataCaptureViewHandler {
    public static let shared = DataCaptureViewHandler()

    private let viewCache = FrameworksViewsCache<FrameworksDataCaptureView>()

    private init() {}

    public var topmostDataCaptureView: FrameworksDataCaptureView? {
        viewCache.getTopMost()
    }

    func removeTopmostView() -> FrameworksDataCaptureView? {
        guard let topmostDataCaptureView = self.topmostDataCaptureView else {
            return nil
        }

        topmostDataCaptureView.dispose()
        return viewCache.remove(viewId: topmostDataCaptureView.viewId)
    }

    func removeView(_ viewId: Int) {
        viewCache.remove(viewId: viewId)?.dispose()
    }

    func removeAllViews() {
        viewCache.disposeAll()
    }

    func addView(_ view: FrameworksDataCaptureView) {
        viewCache.addView(view: view)
    }

    public func getView(_ viewId: Int) -> FrameworksDataCaptureView? {
        viewCache.getView(viewId: viewId)
    }

    public func findFirstOverlayOfType<T: DataCaptureOverlay>() -> T? {
        topmostDataCaptureView?.findFirstOfType()
    }
}
