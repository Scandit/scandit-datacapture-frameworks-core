/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import os

public class AtomicValue<T>
{
    private var lock = os_unfair_lock_s()

    private var _value: T

    public init(_ value: T = false) {
        _value = value
    }

    public var value: T {
        get {
            defer { os_unfair_lock_unlock(&lock) }
            os_unfair_lock_lock(&lock)
            return _value
        }
        set {
            defer { os_unfair_lock_unlock(&lock) }
            os_unfair_lock_lock(&lock)
            _value = newValue
        }
    }
}
