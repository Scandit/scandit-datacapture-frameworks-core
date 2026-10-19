/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public protocol ServiceLocator {
    associatedtype T

    func register(module: T)

    func resolve(clazzName: String) -> T?

    func remove(clazzName: String) -> T?

    func removeAll()
}
