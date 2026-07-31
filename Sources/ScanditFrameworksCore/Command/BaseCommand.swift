/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

/// Base protocol for all command implementations across all modules.
/// Commands encapsulate method calls and their parameters, executing them
/// against the appropriate module with a result handler.
public protocol BaseCommand {
    /// Execute the command.
    ///
    /// - Parameter result: The result handler for async responses
    func execute(result: FrameworksResult)
}
