/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Thrown by a generated type for a property name outside its
/// `additionalProperties: false` allowed set -- catchable separately from a declared field
/// carrying an invalid value. Declared once here, by hand, rather than emitted per module:
/// four distinct types would let a cross-module catch compile and never match. Android
/// shares `UnknownPropertyException` from core the same way.
public struct UnknownPropertyError: Error {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}
