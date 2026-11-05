/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

#if SWIFT_PACKAGE
import _ScanditFrameworksCorePrivate
#endif

final class VolumeButtonObserverTests: XCTestCase {

    func testObserverClassResolvesToScanditCaptureCore() throws {
        let observer = VolumeButtonObserver(handler: {})

        let imagePath = try XCTUnwrap(class_getImageName(type(of: observer)))

        XCTAssertEqual(URL(fileURLWithPath: String(cString: imagePath)).lastPathComponent, "ScanditCaptureCore")
    }
}
