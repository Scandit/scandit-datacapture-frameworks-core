/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Canonical log record shape — mirrors the TS `LogRecord` interface.
///
/// `error.stack` may include file paths from your app binary. It is produced
/// by the Foundation error infrastructure (when an `NSError` is passed in)
/// and kept only in the local in-memory ring buffer for your own diagnostic
/// use. The SDK never reads or transmits this value.
public struct LogRecord {
    public let ts: Int64
    public let level: LogLevel
    public let category: LogCategory
    public let source: String
    public let message: String
    public let fields: [String: Any?]?
    public let durationMs: Int64?
    public let error: LogRecordError?

    public init(
        ts: Int64,
        level: LogLevel,
        category: LogCategory,
        source: String,
        message: String,
        fields: [String: Any?]? = nil,
        durationMs: Int64? = nil,
        error: LogRecordError? = nil
    ) {
        self.ts = ts
        self.level = level
        self.category = category
        self.source = source
        self.message = message
        self.fields = fields
        self.durationMs = durationMs
        self.error = error
    }

    public func toBridgePayload() -> [String: Any?] {
        // Args came from JS/Dart, which already logged them; shipping them back only costs memory.
        let bridgeFields = fields?.filter { $0.key != "args" }
        return [
            "ts": ts,
            "level": level.rawValue,
            "category": category.rawValue,
            "source": source,
            "message": message,
            "fields": (bridgeFields?.isEmpty == false ? bridgeFields : nil) as Any?,
            "durationMs": durationMs as Any?,
            "error": error?.toBridgePayload() as Any?,
        ]
    }
}

public struct LogRecordError {
    public let name: String
    public let message: String
    public let stack: String?

    public init(name: String, message: String, stack: String? = nil) {
        self.name = name
        self.message = message
        self.stack = stack
    }

    public func toBridgePayload() -> [String: Any?] {
        [
            "name": name,
            "message": message,
            "stack": stack as Any?,
        ]
    }
}
