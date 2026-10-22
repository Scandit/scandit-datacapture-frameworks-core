/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import UIKit
import XCTest

@testable import ScanditFrameworksCore

final class DefaultAdvancedOverlayViewCacheTests: XCTestCase {

    // SDC-34482: the scale is read outside any trait callback; a zero scale would make the frame infinite.
    func testCreatedImageViewHasFiniteFrameOutsideTraitCallbacks() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30), format: format).image { _ in }

        let view = DefaultAdvancedOverlayViewCache().getOrCreateView(fromImage: image, withIdentifier: "id")

        let size = try XCTUnwrap(view).frame.size
        // Simulators are 2x/3x: the trait already carries the screen scale, so no fallback applies.
        XCTAssertGreaterThan(UITraitCollection.current.displayScale, 1)
        let expected = 30 / UITraitCollection.current.displayScale
        XCTAssertTrue(size.width.isFinite)
        XCTAssertEqual(size.width, expected, accuracy: 0.001)
        XCTAssertEqual(size.height, expected, accuracy: 0.001)
    }

    func testDisplayScalePrefersTraitScale() {
        XCTAssertEqual(DefaultAdvancedOverlayViewCache.displayScale(traitScale: 2, screenScale: { 3 }), 2)
    }

    func testDisplayScaleFallsBackToScreenScaleWhenTraitScaleIsUnspecified() {
        XCTAssertEqual(DefaultAdvancedOverlayViewCache.displayScale(traitScale: 0, screenScale: { 3 }), 3)
    }

    func testDisplayScaleFallsBackToOneWithoutAScreen() {
        XCTAssertEqual(DefaultAdvancedOverlayViewCache.displayScale(traitScale: 0, screenScale: { nil }), 1)
    }
}
