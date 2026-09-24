/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public protocol FrameworksBaseMode {
    var modeId: Int { get }
    var parentId: Int? { get }
    func dispose()
}
