/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import os

public class AtomicValue<T> {
    private var lock = os_unfair_lock_s()

    private var internalValue: T

    public init(_ value: T = false) {
        internalValue = value
    }

    public var value: T {
        get {
            defer { os_unfair_lock_unlock(&lock) }
            os_unfair_lock_lock(&lock)
            return internalValue
        }
        set {
            defer { os_unfair_lock_unlock(&lock) }
            os_unfair_lock_lock(&lock)
            internalValue = newValue
        }
    }
}
