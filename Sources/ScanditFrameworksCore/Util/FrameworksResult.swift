/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

public protocol FrameworksResult {
    func success(result: Any?)
    func reject(code: String, message: String?, details: Any?)
    func reject(error: Error)

    /// Sends success result and keeps the callback alive for streaming events.
    /// Used for event registration methods. Default implementation calls success().
    func successAndKeepCallback(result: Any?)

    /// Registers callback for specific event names.
    /// Used in event registration flow. Default implementation does nothing.
    func registerCallbackForEvents(_ eventNames: [String])

    /// Unregisters callback for specific event names.
    /// Used in event unregistration flow. Default implementation does nothing.
    func unregisterCallbackForEvents(_ eventNames: [String])

    /// Registers callback for specific event names with a mode ID.
    /// Used in mode-specific event registration flow. Default implementation calls registerCallbackForEvents.
    func registerModeSpecificCallback(_ modeId: Int, eventNames: [String])

    /// Unregisters callback for specific event names with a mode ID.
    /// Used in mode-specific event unregistration flow. Default implementation calls unregisterCallbackForEvents.
    func unregisterModeSpecificCallback(_ modeId: Int, eventNames: [String])

    /// Registers callback for specific event names with a mode ID.
    /// Used in view-specific event registration flow. Default implementation calls registerCallbackForEvents.
    func registerViewSpecificCallback(_ viewId: Int, eventNames: [String])

    /// Unregisters callback for specific event names with a mode ID.
    /// Used in view-specific event unregistration flow. Default implementation calls unregisterCallbackForEvents.
    func unregisterViewSpecificCallback(_ viewId: Int, eventNames: [String])
}

public extension FrameworksResult {
    func success() {
        success(result: nil)
    }

    func registerCallbackForEvents(_ eventNames: [String]) {
        // Default: do nothing (no-op for non-streaming frameworks)
    }

    func unregisterCallbackForEvents(_ eventNames: [String]) {
        // Default: do nothing (no-op for non-streaming frameworks)
    }

    func registerModeSpecificCallback(_ modeId: Int, eventNames: [String]) {
        // Default: do nothing (no-op for non-streaming frameworks)
    }

    func unregisterModeSpecificCallback(_ modeId: Int, eventNames: [String]) {
        // Default: do nothing (no-op for non-streaming frameworks)
    }

    func registerViewSpecificCallback(_ modeId: Int, eventNames: [String]) {
        // Default: do nothing (no-op for non-streaming frameworks)
    }

    func unregisterViewSpecificCallback(_ modeId: Int, eventNames: [String]) {
        // Default: do nothing (no-op for non-streaming frameworks)
    }
}

public class NoopFrameworksResult: FrameworksResult {
    public init() {
    }

    public func success(result: Any?) {
        // Noop
    }

    public func successAndKeepCallback(result: Any?) {
        // Noop
    }

    public func reject(code: String, message: String?, details: Any?) {
        // Noop
    }

    public func reject(error: Error) {
        // Noop
    }
}
