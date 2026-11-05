/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

public enum LogLevel: Int, CaseIterable {
    case off = 0
    case error = 1
    case warn = 2
    case info = 3
    case debug = 4
    case trace = 5

    public var tag: String {
        switch self {
        case .off: return "OFF  "
        case .error: return "ERROR"
        case .warn: return "WARN "
        case .info: return "INFO "
        case .debug: return "DEBUG"
        case .trace: return "TRACE"
        }
    }

    public static func fromRank(_ rank: Int) -> LogLevel {
        LogLevel(rawValue: rank) ?? .off
    }
}
