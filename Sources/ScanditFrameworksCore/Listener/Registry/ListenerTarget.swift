/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

public enum ListenerTarget: Hashable {
    case mode(Int)
    case view(Int)
    case global

    public var key: String {
        switch self {
        case .mode(let id): return "mode:\(id)"
        case .view(let id): return "view:\(id)"
        case .global: return "global"
        }
    }

    public static func of(viewId: Int?, modeId: Int?) -> ListenerTarget {
        if let viewId { return .view(viewId) }
        if let modeId { return .mode(modeId) }
        return .global
    }

}
