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

/// Synchronously dispatches a block to the main thread.
///
/// **WARNING**: Use this ONLY when you absolutely need the block to complete before continuing.
/// This blocks the calling thread until execution finishes.
///
/// **When to use**:
/// - During initialization when subsequent code depends on the result
/// - When accessing UIKit APIs from background threads in synchronous contexts
/// - When you need to guarantee thread-safe access to UI state
///
/// **When NOT to use**:
/// - General UI updates (use `dispatchMain` instead)
/// - Long-running operations (will block the calling thread)
/// - When already on main thread is uncertain (this handles it safely, but async is usually better)
///
/// **Example use case**: Module initialization that creates UI defaults on background thread
/// but needs them ready before returning.
public func dispatchMainSync(_ block: () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}
