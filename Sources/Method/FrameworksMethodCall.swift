/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public protocol FrameworksMethodCall {
    /// Gets the name of the called method.
    ///
    /// - Returns: the method name as a String, not nil.
    var method: String { get }

    /// Returns the arguments of this method call with as [String: Any]
    ///
    /// - Returns: the arguments as [String: Any].
    func arguments() -> [String: Any]

    /// Returns a String-keyed argument of this method call, assuming arguments
    /// are in a Dictionary or similar key-value structure.
    /// The static type of the returned result is determined by the call-site.
    ///
    /// - Parameters:
    ///   - T: the intended type of the argument.
    ///   - key: the String key.
    /// - Returns: the argument value at the specified key, with static type T, or nil,
    /// if such an entry is not present.
    /// - Throws: if arguments cannot be cast to a Dictionary or similar structure.
    func argument<T>(key: String) -> T?

    /// Returns whether this method call involves a mapping for the given argument key,
    /// assuming arguments are a Dictionary or similar key-value structure.
    ///
    /// - Parameter key: the String key.
    /// - Returns: true if arguments is a Dictionary containing key, or similar structure with a mapping for key.
    /// - Throws: if arguments cannot be cast to a Dictionary or similar structure.
    func hasArgument(key: String) -> Bool
}
