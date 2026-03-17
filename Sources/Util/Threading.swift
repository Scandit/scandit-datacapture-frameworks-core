/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation

public func dispatchMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

@discardableResult
public func dispatchMainSync<T>(_ block: () throws -> T) rethrows -> T {
    if Thread.isMainThread {
        return try block()
    }
    return try dispatchMainSyncUnsafe(block)
}

public func dispatchMainSyncUnsafe<T>(_ block: () throws -> T) rethrows -> T {
    return try DispatchQueue.main.sync {
        return try block()
    }
}
