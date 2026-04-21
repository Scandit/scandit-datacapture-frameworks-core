/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import os

public class SessionHolder<T> {
    private var wrapped: T?

    private var lock = os_unfair_lock_s()

    public var value: T? {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return wrapped
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            wrapped = newValue
        }
    }

    public init() {}
}
