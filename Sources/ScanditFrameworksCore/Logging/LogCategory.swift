/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

public struct LogCategory: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let bridge = LogCategory(rawValue: 1 << 0)
    public static let lifecycle = LogCategory(rawValue: 1 << 1)
    public static let listener = LogCategory(rawValue: 1 << 2)
    public static let events = LogCategory(rawValue: 1 << 3)

    public static let defaults: LogCategory = [.bridge, .lifecycle, .listener]
    public static let all: LogCategory = [.bridge, .lifecycle, .listener, .events]

    public var name: String {
        switch rawValue {
        case LogCategory.bridge.rawValue: return "Bridge"
        case LogCategory.lifecycle.rawValue: return "Lifecycle"
        case LogCategory.listener.rawValue: return "Listener"
        case LogCategory.events.rawValue: return "Events"
        default: return "Unknown"
        }
    }
}
