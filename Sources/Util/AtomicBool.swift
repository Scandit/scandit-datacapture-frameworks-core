/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

public class AtomicBool {
    private var lock = os_unfair_lock_s()

    private var _value: Bool

    public init(_ value: Bool = false) {
        _value = value
    }

    public var value: Bool {
        get {
            defer { os_unfair_lock_unlock(&lock) }
            os_unfair_lock_lock(&lock)
            return _value
        }
        set {
            defer { os_unfair_lock_unlock(&lock) }
            os_unfair_lock_lock(&lock)
            if _value != newValue {
                _value = newValue
            }
        }
    }
}
