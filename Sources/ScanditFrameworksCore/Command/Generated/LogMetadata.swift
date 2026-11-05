/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

// THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
// Generator: scripts/bridge_generator/generate.py
// Schema: scripts/bridge_generator/schemas/core.json

import Foundation

/// Per-method `LogRecord` level and category overrides for the core
/// bridge surface. Consulted by `ScanditLogger.emit`: per-frame / per-scan
/// callbacks log at `.trace` under their category label, so they only show once
/// the level is raised to `.trace`.
///
/// Registered as a side effect of the generated `<Module>CommandFactory`'s
/// first `create` call -- no customer wiring required.
enum LogMetadata {
    static let metadata: [String: MethodLogMetadata] = [:]

    static let registered: Void = {
        ScanditLogger.shared.registerMethodMetadata(metadata)
    }()
}
