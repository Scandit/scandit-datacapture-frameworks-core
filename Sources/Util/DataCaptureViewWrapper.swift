/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation

import ScanditCaptureCore
 
public class DataCaptureViewWrapper {
    let dataCaptureView: DataCaptureView
    private var viewOverlays = [DataCaptureOverlay]()

    var overlays: [DataCaptureOverlay] {
        return viewOverlays
    }

    init(dataCaptureView: DataCaptureView) {
        self.dataCaptureView = dataCaptureView
    }

    func addOverlay(_ overlay: DataCaptureOverlay) {
        viewOverlays.append(overlay)
        dispatchMainSync {
            dataCaptureView.addOverlay(overlay)
        }
    }

    func removeOverlay(_ overlay: DataCaptureOverlay) {
        if let index = viewOverlays.firstIndex(where: { $0 === overlay}) {
            viewOverlays.remove(at: index)
            dispatchMainSync {
                dataCaptureView.removeOverlay(overlay)
            }
        }
    }

    func findFirstOfType<T: DataCaptureOverlay>() -> T? {
        return overlays.first { $0 is T } as? T
    }

    func dispose() {
        removeAllOverlays()
        viewOverlays.removeAll()
    }

    func removeAllOverlays() {
        for overlay in overlays {
            removeOverlay(overlay)
        }
    }
}
