/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

public protocol FrameworksResult {
    func success(result: Any?)
    func reject(code: String, message: String?, details: Any?)
    func reject(error: Error)
}

public extension FrameworksResult {
    func success() {
        success(result: nil)
    }
}

public class NoopFrameworksResult: FrameworksResult {
    public init() {
    }

    public func success(result: Any?) {
        // Noop
    }

    public func reject(code: String, message: String?, details: Any?) {
        // Noop
    }

    public func reject(error: Error) {
        // Noop
    }
}
