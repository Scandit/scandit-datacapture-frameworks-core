/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Layer-2 defaults-drift comparator (SDC-32173, DESIGN.md section 4) - Swift port of
/// the Kotlin `DefaultsDriftComparator`
/// (`frameworks/shared/android/scandit-datacapture-frameworks-core/src/androidTest/.../drift/DefaultsDriftComparator.kt`).
/// Same rules, same shape, different host language - kept side-by-side so a change to
/// one platform's comparison semantics is an obvious diff against the other.
///
/// Rules (ticket, non-negotiable):
/// - A SoT field MISSING from the dump is a FAILURE (absence is drift, not a free pass).
/// - A dump key ABSENT from the SoT is a FAILURE (enforces SoT-first authoring, DESIGN.md
///   section 6 - a new default must be authored in the SoT before it ships).
/// - `dynamic`/`typeOnly` entries are STRUCTURAL only: the key must exist and the value's
///   shape must match the declared `type` - the value itself is not compared.
/// - A field carrying a `knownDefect` declaration (SDC-33331) is compared against the
///   documented WRONG value the emitter currently produces, and FAILS both when it matches
///   neither and when it matches the SoT again (the defect got fixed - delete the
///   declaration). See `KnownDefect`.
enum DefaultsDriftComparator {

    struct ExpectedField {
        let type: String
        let value: Any?
        let typeOnly: Bool
        let knownDefect: KnownDefect?

        init(type: String, value: Any?, typeOnly: Bool, knownDefect: KnownDefect? = nil) {
            self.type = type
            self.value = value
            self.typeOnly = typeOnly
            self.knownDefect = knownDefect
        }
    }

    /// A declared known-defect divergence (SDC-33331): the SoT value at this path is CORRECT
    /// and the runtime emitter is not, so the dump legitimately carries `runtimeValue` instead.
    ///
    /// Declared per-path in the SoT (`knownDefect: {reason, ticket?, runtimeValue, platforms?}`)
    /// and stamped into the snapshot by `expected_defaults_generator.py`. This is NOT a
    /// suppression: the field is still value-compared, just against the documented wrong value,
    /// and matching the SoT again FAILS - a fixed defect must have its declaration deleted, so a
    /// declaration cannot silently outlive the bug it documents. Contrast `runtimeSkip`, which
    /// removes the field from the comparison entirely. Mirrors Kotlin's `KnownDefect`.
    struct KnownDefect {
        let reason: String
        let ticket: String?
        let runtimeValue: Any?
    }

    enum ComparatorError: Error {
        case invalidExpectedFile(String)
    }

    /// Parses a committed `expected_defaults_<platform>.json` file.
    static func loadExpected(data: Data) throws -> [String: ExpectedField] {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let fields = root["fields"] as? [String: Any]
        else {
            throw ComparatorError.invalidExpectedFile("missing top-level 'fields' object")
        }
        var result: [String: ExpectedField] = [:]
        for (key, rawEntry) in fields {
            guard let entry = rawEntry as? [String: Any], let type = entry["type"] as? String else {
                throw ComparatorError.invalidExpectedFile("entry '\(key)' missing 'type'")
            }
            var defect: KnownDefect?
            if let declaration = entry["knownDefect"] as? [String: Any] {
                guard let reason = declaration["reason"] as? String else {
                    throw ComparatorError.invalidExpectedFile(
                        "entry '\(key)' has a knownDefect without a 'reason'"
                    )
                }
                guard declaration.keys.contains("runtimeValue") else {
                    throw ComparatorError.invalidExpectedFile(
                        "entry '\(key)' has a knownDefect without a 'runtimeValue'"
                    )
                }
                defect = KnownDefect(
                    reason: reason,
                    ticket: declaration["ticket"] as? String,
                    runtimeValue: declaration["runtimeValue"]
                )
            }
            result[key] = ExpectedField(
                type: type,
                value: entry["value"],
                typeOnly: (entry["typeOnly"] as? Bool) ?? false,
                knownDefect: defect
            )
        }
        return result
    }

    /// The `enrolledModules` key stamped by `expected_defaults_generator.py`
    /// (SDC-32173 F2): the set of SoT modules this snapshot's drift comparison
    /// actually covers. Read this at test start and assert the test's own module
    /// is present - so adding a module to `ENROLLED_MODULES` without a
    /// corresponding test (or vice versa) fails loudly rather than silently.
    static func loadEnrolledModules(data: Data) throws -> Set<String> {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let modules = root["enrolledModules"] as? [String]
        else {
            throw ComparatorError.invalidExpectedFile("missing top-level 'enrolledModules' array")
        }
        return Set(modules)
    }

    /// The `runtimeOnlyPrefixes` key stamped by `expected_defaults_generator.py`
    /// (SDC-33331): runtime subtrees the SoT knowingly does NOT model, each declared in the
    /// SoT by a group-level `runtimeOnlyPrefix: {"reason": ...}` annotation. A dump key at
    /// or below one of these prefixes is not reported as EXTRA; a key explicitly declared
    /// under one still compares normally.
    ///
    /// This is deliberately NOT a return of the hardcoded `outOfScope` set that SDC-32173
    /// review finding F1 deleted from the test files. That set was an undocumented filter
    /// living in a test; this list is authored in the SoT with a mandatory written reason
    /// and flows through the generator into the committed snapshot, so adding an entry is a
    /// reviewed, auditable diff. The SoT-first rule (DESIGN.md section 6) is untouched for
    /// everything else. Mirrors Kotlin's `loadRuntimeOnlyPrefixes`.
    ///
    /// Only the prefixes are returned - the reasons exist for the human reading the
    /// snapshot/diff, not for the comparison. An absent key is an empty list, so a snapshot
    /// generated before this key existed still loads.
    static func loadRuntimeOnlyPrefixes(data: Data) throws -> [String] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ComparatorError.invalidExpectedFile("not a JSON object")
        }
        guard let entries = root["runtimeOnlyPrefixes"] as? [[String: Any]] else {
            return []
        }
        return entries.compactMap { $0["prefix"] as? String }
    }

    /// Flattens a nested `getDefaults()`-shaped dump to dotted runtime paths, prefixed by
    /// `modulePrefix` (e.g. "Core"). Recursion stops as soon as the accumulated path matches
    /// a key in `expectedPaths` - lets a `type: object` SoT entry be captured as a single
    /// leaf instead of being flattened past its own boundary.
    static func flatten(
        dump: [String: Any?],
        modulePrefix: String,
        expectedPaths: Set<String>
    ) -> [String: Any?] {
        var out: [String: Any?] = [:]

        // Every proper ancestor of an expected path, so a node can ask "is anything expected
        // BELOW me?" without scanning the whole set per node. Mirrors Kotlin.
        var expectedAncestors = Set<String>()
        for p in expectedPaths {
            var idx = p.startIndex
            while let dot = p[idx...].firstIndex(of: ".") {
                expectedAncestors.insert(String(p[p.startIndex..<dot]))
                idx = p.index(after: dot)
                if idx >= p.endIndex { break }
            }
        }

        func recurse(_ node: Any?, _ path: String) {
            if expectedPaths.contains(path) {
                out[path] = node
                return
            }
            // SDC-33331: several bridges hand back a whole sub-tree as ONE JSON-encoded
            // string rather than a nested map - e.g. BarcodeAr's `barcodeArFeedback`, and
            // Label's `feedback` on iOS. Recursion would stop on that string, so every SoT
            // sub-path under it reported MISSING while the string itself reported EXTRA.
            // Parse and keep descending when the SoT expects structure below this path.
            // Mirrors Kotlin's identical branch - these two comparators must agree.
            if let string = node as? String, expectedAncestors.contains(path),
                let data = string.data(using: .utf8),
                let parsed = try? JSONSerialization.jsonObject(with: data),
                let map = parsed as? [String: Any]
            {
                for (k, v) in map {
                    recurse(v, "\(path).\(k)")
                }
                return
            }
            if let map = node as? [String: Any?], !map.isEmpty {
                for (k, v) in map {
                    recurse(v, "\(path).\(k)")
                }
            } else if let map = node as? [String: Any], !map.isEmpty {
                for (k, v) in map {
                    recurse(v, "\(path).\(k)")
                }
            } else if (node as? [String: Any?])?.isEmpty == true || (node as? [String: Any])?.isEmpty == true {
                // An empty map here is the synthetic parent left behind once every leaf
                // under it has been filtered out upstream - not a real extra key, so it
                // must not be emitted as one (SDC-32173 review F1: this was previously
                // worked around per-path in the test's outOfScope set).
            } else {
                out[path] = node
            }
        }

        for (key, value) in dump {
            recurse(value, "\(modulePrefix).\(key)")
        }
        return out
    }

    /// Compares `actual` (a `flatten`-produced map) against `expected`, restricted to
    /// paths starting with one of `scopePrefixes`.
    ///
    /// `runtimeOnlyPrefixes` (from `loadRuntimeOnlyPrefixes`) suppresses the EXTRA report
    /// for paths at or below a knowingly-unmodelled runtime subtree. It affects ONLY the
    /// EXTRA loop: a path that IS declared in `expected` is compared as usual even when it
    /// sits under such a prefix. Mirrors Kotlin's `compare`.
    ///
    /// Returns one human-actionable message per mismatch - never a blob diff. Empty array
    /// = no drift.
    static func compare(
        actual: [String: Any?],
        expected: [String: ExpectedField],
        scopePrefixes: [String],
        runtimeOnlyPrefixes: [String] = []
    ) -> [String] {
        func inScope(_ path: String) -> Bool {
            scopePrefixes.contains { path == $0 || path.hasPrefix("\($0).") }
        }
        // A prefix that EQUALS the key suppresses that single key - several declarations
        // (e.g. Barcode.Barcode.SymbologyDescriptions) name one runtime leaf, not a subtree.
        func isRuntimeOnly(_ path: String) -> Bool {
            runtimeOnlyPrefixes.contains { path == $0 || path.hasPrefix("\($0).") }
        }

        var failures: [String] = []
        let expectedInScope = expected.filter { inScope($0.key) }
        let actualInScope = actual.filter { inScope($0.key) }

        for (path, field) in expectedInScope {
            guard let actualValueRaw = actualInScope[path] else {
                failures.append(
                    "MISSING FROM DUMP: '\(path)' is declared in the SoT "
                        + "(type=\(field.type), value=\(String(describing: field.value))) but "
                        + "getDefaults() has no entry at that runtime path - absence is drift, "
                        + "not acceptable."
                )
                continue
            }
            let actualValue = normalizeActual(actualValueRaw, field.type)
            if field.typeOnly {
                // Dynamic/type-only entries assert PRESENCE, not shape, when the runtime
                // value is null or empty: a dynamic value is by definition environment-
                // dependent (e.g. Core.Camera.defaultPosition/availablePositions on a
                // camera-less iOS Simulator resolve to nil/[]) - that is not drift, so the
                // declared type is only checked when a real value is present (SDC-32173
                // review F1 follow-up).
                if !isNullOrEmpty(actualValue) && !matchesType(actualValue, field.type) {
                    failures.append(
                        "DYNAMIC TYPE MISMATCH: '\(path)' expected structural type "
                            + "'\(field.type)' (value not compared, dynamic.json) but dump value "
                            + "'\(String(describing: actualValue))' does not match."
                    )
                }
                continue
            }
            // Colour canonicalization applies to `object`/`array` too, not just a `color`
            // leaf: colours live INSIDE brushes and feedback blocks (SDC-33331). Deliberately
            // NOT applied to `string`/`enum`. Mirrors Kotlin.
            let canonicalize = field.type == "color" || field.type == "object" || field.type == "array"
            let expectedValue = canonicalize ? canonicalColor(field.value) : field.value
            let comparableActual = canonicalize ? canonicalColor(actualValue) : actualValue
            let matchesSot = deepEquals(expectedValue, comparableActual)
            if let defect = field.knownDefect {
                // The SoT is right and the emitter is wrong at this path, on purpose and in
                // writing. Three outcomes, and two of them fail (SDC-33331) - see `KnownDefect`.
                // Mirrors Kotlin's identical branch.
                let defectValue = canonicalize ? canonicalColor(defect.runtimeValue) : defect.runtimeValue
                let ticket = defect.ticket.map { " (\($0))" } ?? " (no ticket filed)"
                if matchesSot {
                    failures.append(
                        "KNOWN DEFECT APPEARS FIXED: '\(path)' now matches the SoT\(ticket). "
                            + "Remove the knownDefect declaration from the SoT - a stale "
                            + "declaration hides real drift. Declared defect: \(defect.reason)"
                    )
                } else if !deepEquals(defectValue, comparableActual) {
                    failures.append(
                        "VALUE DRIFT: '\(path)' matches NEITHER the SoT nor the declared known "
                            + "defect\(ticket) - SoT value=\(String(describing: field.value)) "
                            + "(type=\(field.type)), declared defect "
                            + "value=\(String(describing: defect.runtimeValue)), dump "
                            + "value=\(String(describing: actualValue)). The defect changed shape "
                            + "or a second drift landed on top of it; re-check the emitter and "
                            + "update or remove the knownDefect declaration. Declared defect: "
                            + "\(defect.reason)"
                    )
                }
                continue
            }
            if !matchesSot {
                failures.append(
                    "VALUE DRIFT: '\(path)' SoT value=\(String(describing: field.value)) "
                        + "(type=\(field.type)) != dump value=\(String(describing: actualValue)) - "
                        + "either fix the SoT transcription or annotate runtimeKey/runtimeSkip "
                        + "if this is a legitimate divergence (values.ios for a real iOS-vs-"
                        + "Android split, runtimeSkip only when there is truly no dump "
                        + "counterpart)."
                )
            }
        }

        for path in actualInScope.keys where expectedInScope[path] == nil && !isRuntimeOnly(path) {
            failures.append(
                "EXTRA IN DUMP: '\(path)' (value=\(String(describing: actualInScope[path] ?? nil))) "
                    + "is returned by getDefaults() but has no SoT entry - author it in "
                    + "scripts/defaults_generator/defaults/*.json first (DESIGN.md section 6)."
            )
        }

        return failures
    }

    /// Parses a JSON-encoded String leaf (or a per-element JSON-encoded String list) into
    /// a Dictionary/Array when the SoT declares it structured.
    private static func normalizeActual(_ value: Any?, _ type: String) -> Any? {
        if type == "array", let list = value as? [Any?] {
            return list.map { normalizeActual($0, "object") }
        }
        guard let string = value as? String else { return value }
        switch type {
        case "object":
            guard let data = string.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data)
            else { return string }
            return obj
        case "array":
            guard let data = string.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data)
            else { return string }
            return obj
        default:
            return string
        }
    }

    /// Colors compare equal regardless of `#` prefix / case: the SoT authors
    /// `#RRGGBBAA` (DESIGN.md section 2's color-token convention) while the native
    /// iOS bridges (e.g. `EncodableBrush`/`glui::Color`-derived hex helpers) emit a
    /// bare lowercase `rrggbbaa` with no `#` - same color, different string
    /// convention, not a real value drift.
    /// SDC-33331: applied at ANY depth, not just to a top-level color leaf. A `brush` is an
    /// OBJECT ({fill:{color:...}, stroke:{color:..., width:...}}), so a brush whose only
    /// difference was colour casing reported VALUE DRIFT on a field that had not drifted.
    /// Only hex-colour-SHAPED strings are touched (6 or 8 hex digits, optional `#`), and the
    /// same normalization is applied to both sides. Mirrors Kotlin's `canonicalColor`.
    private static func canonicalColor(_ value: Any?) -> Any? {
        if let string = value as? String {
            guard isHexColor(string) else { return string }
            return string.hasPrefix("#") ? String(string.dropFirst()).lowercased() : string.lowercased()
        }
        if let map = value as? [String: Any?] {
            return map.mapValues { canonicalColor($0) }
        }
        if let map = value as? [String: Any] {
            return map.mapValues { canonicalColor($0) as Any }
        }
        if let list = value as? [Any?] {
            return list.map { canonicalColor($0) }
        }
        return value
    }

    private static func isHexColor(_ string: String) -> Bool {
        let body = string.hasPrefix("#") ? String(string.dropFirst()) : string
        guard body.count == 6 || body.count == 8 else { return false }
        return body.allSatisfy(\.isHexDigit)
    }

    /// objCType codes (see `NSNumber.objCType`) for the signed/unsigned integer
    /// encodings - deliberately excludes "f"/"d" (Float/Double), so a Double-backed
    /// NSNumber (e.g. a dynamic field arriving as a floating value) is rejected here,
    /// matching Kotlin's `value is Int || value is Long` (SDC-32173 review F4): the two
    /// "mirror" comparators must enforce the same rule for the same declared type.
    private static let integerObjCTypeCodes: Set<String> = ["c", "i", "s", "l", "q", "C", "I", "S", "L", "Q"]

    /// True for a nil leaf or an empty array/dictionary - the "no value yet" shapes a
    /// dynamic/type-only field can legitimately take on an environment that hasn't
    /// populated it (no camera hardware, no license, etc). Must agree with Kotlin's
    /// `isNullOrEmpty` (SDC-32173 review F1 follow-up: comparator divergence is a defect).
    private static func isNullOrEmpty(_ value: Any?) -> Bool {
        guard let value = value else { return true }
        if let array = value as? [Any?] { return array.isEmpty }
        if let array = value as? [Any] { return array.isEmpty }
        if let dict = value as? [String: Any?] { return dict.isEmpty }
        if let dict = value as? [String: Any] { return dict.isEmpty }
        return false
    }

    private static func matchesType(_ value: Any?, _ type: String) -> Bool {
        switch type {
        case "bool": return value is Bool
        case "int":
            guard let number = value as? NSNumber, !(value is Bool) else { return false }
            return integerObjCTypeCodes.contains(String(cString: number.objCType))
        case "number": return value is NSNumber || value is Double || value is Int
        case "string", "enum", "color": return value is String
        case "object": return value is [String: Any] || value is [String: Any?]
        case "array": return value is [Any] || value is [Any?]
        default: return true
        }
    }

    private static func deepEquals(_ expected: Any?, _ actual: Any?) -> Bool {
        switch (expected, actual) {
        case (let e as NSNumber, let a as NSNumber):
            // A Float default (e.g. 0.8f) can round-trip with a tiny epsilon of error -
            // guard the same way the Kotlin comparator does.
            return abs(e.doubleValue - a.doubleValue) < 1e-6
        case (let e as [String: Any?], let a as [String: Any?]):
            guard Set(e.keys) == Set(a.keys) else { return false }
            return e.keys.allSatisfy { deepEquals(e[$0] ?? nil, a[$0] ?? nil) }
        case (let e as [String: Any], let a as [String: Any]):
            guard Set(e.keys) == Set(a.keys) else { return false }
            return e.keys.allSatisfy { deepEquals(e[$0], a[$0]) }
        case (let e as [Any?], let a as [Any?]):
            guard e.count == a.count else { return false }
            return zip(e, a).allSatisfy { deepEquals($0, $1) }
        case (let e as String, let a as String):
            return e == a
        case (nil, nil), (nil, is NSNull), (is NSNull, nil), (is NSNull, is NSNull):
            // JSONSerialization decodes a JSON null as NSNull, not Swift nil, and BOTH
            // operands come from it - so a field legitimately null on both sides arrives
            // as (NSNull, NSNull). Without this the fail-closed default below reports a
            // spurious VALUE DRIFT. Kotlin has no such gap (`null == null`).
            return true
        default:
            // Dynamic types that don't hit one of the typed cases above (e.g. an
            // expected String vs an actual NSNumber) are a real type-change drift -
            // fail closed rather than falling back to a lossy description compare,
            // which previously made such mismatches compare EQUAL (SDC-32173 review
            // Major 1). Matches Kotlin's plain `expected == actual` fallback.
            return false
        }
    }
}
