/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public struct OverlayEntry {
    /// Identity key in the form `type:modeId`, used for diffing overlays.
    public let key: String
    /// The overlay type extracted from `key` (the part before `:`).
    public let type: String
    /// The raw JSON string passed to the deserialization dispatcher.
    public let jsonString: String

    static func from(overlayDict: [String: Any]) -> OverlayEntry? {
        guard let type = overlayDict["type"] as? String,
            let data = try? JSONSerialization.data(withJSONObject: overlayDict),
            let jsonString = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        let modeId = overlayDict["modeId"] as? Int ?? -1
        return OverlayEntry(key: "\(type):\(modeId)", type: type, jsonString: jsonString)
    }
}

public class DataCaptureViewCreationData {
    let viewId: Int
    let parentId: Int?
    let viewJson: String
    let overlays: [OverlayEntry]

    private init(
        viewId: Int,
        parentId: Int?,
        viewJson: String,
        overlays: [OverlayEntry]
    ) {
        self.viewId = viewId
        self.parentId = parentId
        self.viewJson = viewJson
        self.overlays = overlays
    }

    /// Parses `viewId`/`parentId` via the generated `SchemaTypes.DataCaptureViewPayload`
    /// (`layer: "framework"` projection of `core/data_capture_view.json`, SDC-33315).
    /// `overlays` is `layer: "c++"` and is hand-parsed below, then stripped before the
    /// remaining JSON is forwarded to native.
    ///
    /// Two failure classes on the generated decode are handled differently: an UNKNOWN
    /// property name is a schema-vs-wire drift risk (the schema listing N keys is not proof
    /// the wire never sends more, cf. SDC-32646), so it degrades to a legacy per-key read of
    /// `viewId`/`parentId`. A DECLARED field with an INVALID VALUE is never tolerated, on
    /// this fallback path or the happy path, with or without a co-occurring unknown key --
    /// `requireIntegral` re-runs the generated decode's own Number/integral/range check.
    ///
    /// The degrade logs a warning, but `ScanditLogger` starts at `.off`, so drift is
    /// discoverable on demand rather than reported by default.
    ///
    /// Three pre-existing splits are left alone, all stricter on Android: a MISSING
    /// `viewId` (throws there, `0` here), an unparseable `jsonString` (throws there,
    /// defaults here), and an explicit `viewId: null` (rejected there, read as absent here).
    ///
    /// - Throws: `UnknownPropertyError` is caught internally. Any other decode
    ///   error, or an error from `requireIntegral`, propagates.
    static func fromJson(_ jsonString: String) throws -> DataCaptureViewCreationData {
        guard let jsonData = jsonString.data(using: .utf8),
            var json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            // Return default values if JSON parsing fails
            return DataCaptureViewCreationData(
                viewId: 0,
                parentId: nil,
                viewJson: "{}",
                overlays: []
            )
        }

        let overlays = getOverlaysFromViewJson(&json)

        // Decodes from the original `jsonData`, not a re-serialization of the (overlays-
        // stripped) `json` dict: `overlays` is already in the schema's `all_property_names`,
        // so the allowedKeys check accepts it without decoding it.
        let parsed: SchemaTypes.DataCaptureViewPayload?
        do {
            parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: jsonData)
        } catch let error as UnknownPropertyError {
            ScanditLogger.shared.emit(
                level: .warn,
                category: .bridge,
                source: "DataCaptureViewCreationData",
                message: "DataCaptureViewPayload decode: falling back to legacy parse: \(error.message)"
            )
            parsed = nil
        }

        return DataCaptureViewCreationData(
            viewId: try parsed?.viewId ?? requireIntegral(json, key: Constants.viewIdKey) ?? 0,
            parentId: try parsed?.parentId ?? requireIntegral(json, key: Constants.parentIdKey),
            viewJson: convertToJsonString(json) ?? "{}",
            overlays: overlays
        )
    }

    /// Reads `key` from `json` as an `Int`: present, an integral `NSNumber` (zero fractional
    /// part), and within `Int32` range. The generated Kotlin type for an `integer` property is
    /// `Int` (32-bit), so a value outside that range is not representable on Android at all;
    /// bounding both platforms to it is what lets them agree, rather than widening Android to
    /// `Long` (`SchemaAssertions.isIntegral`, the Kotlin counterpart of this check).
    ///
    /// Returns `nil` when `key` is absent or explicitly `null` -- missing-key handling is
    /// intentionally per-platform (Kotlin throws for a missing `viewId`; Swift defaults it to
    /// `0` at the call site above) and untouched here. Throws for any other invalid value.
    private static func requireIntegral(_ json: [String: Any], key: String) throws -> Int? {
        guard let raw = json[key], !(raw is NSNull) else {
            return nil
        }
        // A JSON boolean bridges to `NSNumber`, so `true` would otherwise return 1.
        // `raw is Bool` cannot exclude it -- Foundation bridges NSNumber 0 and 1 to `Bool`,
        // so that test rejects `viewId: 0` too. Only the CF type id separates the two.
        guard let number = raw as? NSNumber,
            CFGetTypeID(number) != CFBooleanGetTypeID()
        else {
            throw InvalidFieldValueError(message: "\(key): expected an integer, got \(raw)")
        }
        let value = number.doubleValue
        guard value.isFinite,
            value == value.rounded(.towardZero),
            value >= Double(Int32.min),
            value <= Double(Int32.max)
        else {
            throw InvalidFieldValueError(message: "\(key): expected an integer, got \(raw)")
        }
        return number.intValue
    }

    private static func getOverlaysFromViewJson(_ json: inout [String: Any]) -> [OverlayEntry] {
        var overlays: [OverlayEntry] = []

        if let overlayDicts = json[Constants.overlaysKey] as? [[String: Any]] {
            for dict in overlayDicts {
                if let entry = OverlayEntry.from(overlayDict: dict) {
                    overlays.append(entry)
                }
            }
        }
        json.removeValue(forKey: Constants.overlaysKey)
        return overlays
    }

    private static func convertToJsonString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    private struct Constants {
        static let overlaysKey = "overlays"
        static let viewIdKey = "viewId"
        static let parentIdKey = "parentId"
    }
}

/// Thrown by `DataCaptureViewCreationData.requireIntegral` for a declared field (`viewId`,
/// `parentId`) whose value is invalid on the unknown-key fallback path. Being a distinct type
/// from `UnknownPropertyError` is what lets `fromJson` itself tell the two failure classes
/// apart -- which is all it is for. It is deliberately NOT the one catchable type for the
/// invalid-value class the way `UnknownPropertyError` is for the unknown-key class: it is
/// internal to this module, and the generated decoder signals the same class as
/// `DecodingError`, since that is what a `Codable` `init(from:)` is expected to throw.
struct InvalidFieldValueError: Error {
    let message: String
}
