/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

// THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
// Generator: scripts/bridge_generator/generate.py
// Schema: scripts/bridge_generator/schemas/core.json
//
// Codable structs/enums derived from the serialization JSON schemas
// referenced by this module's bridge params -- the Swift twin of
// `SchemaTypes.kt` (SDC-32644) / `schemaTypes.ts` / `schema_types.dart`. No
// runtime dependency beyond Foundation: validation rides Codable's own
// throwing contract, hand-extended below for the keywords Codable doesn't
// natively enforce.
//
// init(from:) enforces the same JSON Schema keywords the Kotlin/Dart
// emitters do: required, type, enum, string const, additionalProperties,
// null-ness, and root-level oneOf (dispatched on the discriminator). NOT
// enforced -- a payload violating one of these still decodes: pattern,
// minimum/maximum, minLength/maxLength, multipleOf.
//
// Like the Kotlin emitter's `SchemaAssertions.requireValid` (SDC-33621:
// throws unconditionally in every build variant), every check below
// throws unconditionally in every build configuration: there is no
// `#if DEBUG` idiom in frameworks/shared/ios today, and Codable's
// `Decodable.init(from:)` throws by contract regardless of build config
// -- gating strictness behind DEBUG would fight the protocol it
// implements. Required-field absence, a null on a non-optional
// property, and a type mismatch are all
// surfaced automatically by `KeyedDecodingContainer.decode(_:forKey:)`
// (native `DecodingError.keyNotFound` / `.valueNotFound` /
// `.typeMismatch`) -- EXCEPT for a property that is both `required` and
// `nullable`, which must accept an explicit null while still rejecting a
// missing key; `decode(_:forKey:)` can't express that (it rejects null
// too) and plain `decodeIfPresent` can't express it either (it treats a
// missing key and an explicit null identically, both -> nil), so that case
// gets a hand-rolled `container.contains(forKey:)` guard below that throws
// `DecodingError.keyNotFound` before falling through to `decodeIfPresent`.
// unknown-enum-value and unknown-key (`additionalProperties: false`)
// checks are likewise hand-rolled below and throw
// `DecodingError.dataCorrupted` with a message naming the offending
// key/value.
//
// Full required/nullable matrix, kept coherent across every property kind
// (plain scalar, enum, array, ref, union) and both directions:
//
//   not required (nullable or not):
//     decode: missing key -> nil; explicit `null` -> nil.
//     encode: `nil` -> key omitted (`encodeIfPresent` / `if let`).
//   required, non-nullable:
//     decode: missing key -> throws `keyNotFound`; explicit `null` -> throws
//       `valueNotFound` (from `decode(_:forKey:)`, or from the union
//       parser's own decode when it hits null).
//     encode: always encodes the key (non-optional Swift property).
//   required, nullable:
//     decode: missing key -> throws `keyNotFound` (hand-rolled
//       `required_key_guard` below, since `decodeIfPresent`/`decodeNil`
//       alone can't distinguish missing-key from explicit-null); explicit
//       `null` -> nil.
//     encode: `nil` -> key present with an explicit `null`
//       (`encodeNil(forKey:)`), never omitted -- omitting it here would
//       make `init(from:)` throw `keyNotFound` on round-trip.
//
// A union-typed property follows the same matrix, but "decode" means
// dispatching through `<Union>Parser.parse(from:)` against a
// `superDecoder`; since that parser cannot itself observe null (it reads a
// discriminator key out of the nested container), every union branch below
// checks `decodeNil`/`contains` itself before ever calling into the parser.

import Foundation

// Reusable dynamic `CodingKey` for enumerating every key actually present
// in the payload -- needed only to implement `additionalProperties: false`
// (an unknown-key check), since a container keyed by a fixed `CodingKeys`
// enum never surfaces keys it doesn't already know about.
private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

// Codable stand-in for a property (or array element) the generator cannot
// give a nominal type -- an inline anonymous object with no `$ref`/`$defs`,
// like `barcode_ar_filter_filter_barcodes.json`'s `barcodes` items.
//
// Kotlin, Dart and TypeScript can spell "untyped" directly (`Any?`,
// `Object?`, `unknown`), so they render such a property as-is. Swift cannot:
// `Any` is not `Codable`, so `container.decode([Any].self, ...)` has no
// matching overload and the file does not compile. This enum is the Swift
// spelling of the same idea -- it round-trips arbitrary JSON without
// asserting a shape, so element-level validation stays exactly as absent
// here as it is on the other three platforms.
// Internal rather than `private`: unlike `AnyCodingKey` (used only inside
// function bodies), this type appears in the stored-property types of the
// generated structs, and Swift rejects an internal property whose type is
// private.
enum AnyJSON: Codable {
    case string(String)
    case number(Double)
    case integer(Int)
    case bool(Bool)
    case array([AnyJSON])
    case object([String: AnyJSON])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            // Int before Double: `decode(Double.self)` also accepts an
            // integer literal, and matching Double first would turn every
            // whole number into `1.0` on re-encode.
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnyJSON].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyJSON].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "AnyJSON: value is not representable as JSON"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    // Projection back to the plain Foundation JSON types that
    // `Event.emit(on:payload: [String: Any])` serializes.
    var jsonObject: Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        case .integer(let value): return value
        case .bool(let value): return value
        case .array(let value): return value.map(\.jsonObject)
        case .object(let value): return value.mapValues(\.jsonObject)
        case .null: return NSNull()
        }
    }
}

// Namespace container for every generated type below. A schema title is
// only unique within its own schema file (`serialization/schemas/**`); the
// Kotlin emitter gets collision safety for free from its
// `...command.generated` *package*, and the TS/Dart emitters keep their
// generated types out of the public barrel -- but a Swift target has no
// per-directory namespace and no barrel to exclude from, so an unqualified
// top-level type here can shadow an unrelated SDK type of the same name
// (e.g. a schema titled "SequenceFrameSource" collided with
// `SDCSequenceFrameSource`'s `NS_SWIFT_NAME(SequenceFrameSource)` from
// ScanditCaptureCore -- see SDC-32645). Wrapping every generated
// declaration in this uninhabited `enum` namespaces all of them under
// `SchemaTypes.<Name>`, so unqualified references elsewhere in the module
// keep resolving to the real SDK type.
enum SchemaTypes {

    /// A frame source that processes externally provided frames in the order they are added.
    struct SequenceFrameSource: Codable {
        let type: String
        let id: String?
        let position: String
        let lensPosition: Double?
        let desiredState: String?

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            type: String,
            id: String? = nil,
            position: String,
            lensPosition: Double? = nil,
            desiredState: String? = nil
        ) {
            self.type = type
            self.id = id
            self.position = position
            self.lensPosition = lensPosition
            self.desiredState = desiredState
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "type",
            "id",
            "position",
            "lensPosition",
            "desiredState",
        ]
        private static let typeAllowedValues: Set<String> = ["sequence"]
        private static let positionAllowedValues: Set<String> = ["worldFacing", "userFacing", "unspecified"]
        private static let desiredStateAllowedValues: Set<String> = ["on", "off", "standby"]

        enum CodingKeys: String, CodingKey {
            case type
            case id
            case position
            case lensPosition
            case desiredState
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "SequenceFrameSource: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typeRaw = try container.decode(String.self, forKey: .type)
            guard Self.typeAllowedValues.contains(typeRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "SequenceFrameSource.type: unknown enum value '\(typeRaw)'"
                    )
                )
            }
            type = typeRaw
            id = try container.decodeIfPresent(String.self, forKey: .id)
            let positionRaw = try container.decode(String.self, forKey: .position)
            guard Self.positionAllowedValues.contains(positionRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "SequenceFrameSource.position: unknown enum value '\(positionRaw)'"
                    )
                )
            }
            position = positionRaw
            lensPosition = try container.decodeIfPresent(Double.self, forKey: .lensPosition)
            let desiredStateRaw = try container.decodeIfPresent(String.self, forKey: .desiredState)
            if let desiredStateRaw {
                guard Self.desiredStateAllowedValues.contains(desiredStateRaw) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription:
                                "SequenceFrameSource.desiredState: unknown enum value '\(desiredStateRaw)'"
                        )
                    )
                }
            }
            desiredState = desiredStateRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(id, forKey: .id)
            try container.encode(position, forKey: .position)
            try container.encodeIfPresent(lensPosition, forKey: .lensPosition)
            try container.encodeIfPresent(desiredState, forKey: .desiredState)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["type"] = type
            if let id { dict["id"] = id }
            dict["position"] = position
            if let lensPosition { dict["lensPosition"] = lensPosition }
            if let desiredState { dict["desiredState"] = desiredState }
            return dict
        }
    }

    /// The view that renders the camera feed and overlays for data capture.
    struct DataCaptureViewPayload: Codable {
        let viewId: Int?
        let parentId: Int?

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            viewId: Int? = nil,
            parentId: Int? = nil
        ) {
            self.viewId = viewId
            self.parentId = parentId
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "viewId",
            "parentId",
            "pointOfInterest",
            "scanAreaMargins",
            "logoAnchor",
            "logoOffset",
            "logoHidden",
            "logoStyle",
            "overlays",
            "controls",
            "focusGesture",
            "zoomGesture",
            "zoomGestures",
            "optimizesRendering",
            "shouldShowZoomNotification",
            "properties",
        ]

        enum CodingKeys: String, CodingKey {
            case viewId
            case parentId
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "DataCaptureViewPayload: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            viewId = try container.decodeIfPresent(Int.self, forKey: .viewId)
            if let viewId {
                guard viewId >= Int(Int32.min), viewId <= Int(Int32.max) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "DataCaptureViewPayload.viewId: out of Int32 range"
                        )
                    )
                }
            }
            parentId = try container.decodeIfPresent(Int.self, forKey: .parentId)
            if let parentId {
                guard parentId >= Int(Int32.min), parentId <= Int(Int32.max) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "DataCaptureViewPayload.parentId: out of Int32 range"
                        )
                    )
                }
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(viewId, forKey: .viewId)
            try container.encodeIfPresent(parentId, forKey: .parentId)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            if let viewId { dict["viewId"] = viewId }
            dict["parentId"] = parentId ?? NSNull()
            return dict
        }
    }

    /// Notifies the listener that the frame source's state changed.
    struct FrameSourceListenerOnStateChanged: Codable {
        let state: String
        let cameraPosition: String?
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            state: String,
            cameraPosition: String? = nil,
            event: String
        ) {
            self.state = state
            self.cameraPosition = cameraPosition
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "state",
            "cameraPosition",
            "event",
        ]
        private static let stateAllowedValues: Set<String> = [
            "on", "off", "starting", "stopping", "standby", "bootingUp", "wakingUp", "goingToSleep", "shuttingDown",
        ]
        private static let cameraPositionAllowedValues: Set<String> = ["worldFacing", "userFacing", "unspecified"]
        private static let eventAllowedValues: Set<String> = ["FrameSourceListener.onStateChanged"]

        enum CodingKeys: String, CodingKey {
            case state
            case cameraPosition
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "FrameSourceListenerOnStateChanged: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let stateRaw = try container.decode(String.self, forKey: .state)
            guard Self.stateAllowedValues.contains(stateRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "FrameSourceListenerOnStateChanged.state: unknown enum value '\(stateRaw)'"
                    )
                )
            }
            state = stateRaw
            let cameraPositionRaw = try container.decodeIfPresent(String.self, forKey: .cameraPosition)
            if let cameraPositionRaw {
                guard Self.cameraPositionAllowedValues.contains(cameraPositionRaw) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription:
                                "FrameSourceListenerOnStateChanged.cameraPosition: unknown enum value '\(cameraPositionRaw)'"
                        )
                    )
                }
            }
            cameraPosition = cameraPositionRaw
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "FrameSourceListenerOnStateChanged.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(state, forKey: .state)
            try container.encodeIfPresent(cameraPosition, forKey: .cameraPosition)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["state"] = state
            dict["cameraPosition"] = cameraPosition ?? NSNull()
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the torch state changed.
    struct TorchListenerOnTorchStateChanged: Codable {
        let state: String
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            state: String,
            event: String
        ) {
            self.state = state
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "state",
            "event",
        ]
        private static let stateAllowedValues: Set<String> = ["on", "off", "auto"]
        private static let eventAllowedValues: Set<String> = ["TorchListener.onTorchStateChanged"]

        enum CodingKeys: String, CodingKey {
            case state
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "TorchListenerOnTorchStateChanged: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let stateRaw = try container.decode(String.self, forKey: .state)
            guard Self.stateAllowedValues.contains(stateRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "TorchListenerOnTorchStateChanged.state: unknown enum value '\(stateRaw)'"
                    )
                )
            }
            state = stateRaw
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "TorchListenerOnTorchStateChanged.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(state, forKey: .state)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["state"] = state
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the camera's zoom level changed.
    struct ZoomListenerOnZoomLevelChanged: Codable {
        let oldZoomLevel: Double
        let newZoomLevel: Double
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            oldZoomLevel: Double,
            newZoomLevel: Double,
            event: String
        ) {
            self.oldZoomLevel = oldZoomLevel
            self.newZoomLevel = newZoomLevel
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "oldZoomLevel",
            "newZoomLevel",
            "event",
        ]
        private static let eventAllowedValues: Set<String> = ["ZoomListener.onZoomLevelChanged"]

        enum CodingKeys: String, CodingKey {
            case oldZoomLevel
            case newZoomLevel
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "ZoomListenerOnZoomLevelChanged: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            oldZoomLevel = try container.decode(Double.self, forKey: .oldZoomLevel)
            newZoomLevel = try container.decode(Double.self, forKey: .newZoomLevel)
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "ZoomListenerOnZoomLevelChanged.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(oldZoomLevel, forKey: .oldZoomLevel)
            try container.encode(newZoomLevel, forKey: .newZoomLevel)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["oldZoomLevel"] = oldZoomLevel
            dict["newZoomLevel"] = newZoomLevel
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the macro mode changed. iOS-only: CoreModule deliberately no-ops this
    /// on Android (macro mode is not available there).
    struct MacroModeListenerOnMacroModeChanged: Codable {
        let macroMode: String
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            macroMode: String,
            event: String
        ) {
            self.macroMode = macroMode
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "macroMode",
            "event",
        ]
        private static let macroModeAllowedValues: Set<String> = ["on", "off", "auto"]
        private static let eventAllowedValues: Set<String> = ["MacroModeListener.onMacroModeChanged"]

        enum CodingKeys: String, CodingKey {
            case macroMode
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "MacroModeListenerOnMacroModeChanged: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let macroModeRaw = try container.decode(String.self, forKey: .macroMode)
            guard Self.macroModeAllowedValues.contains(macroModeRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription:
                            "MacroModeListenerOnMacroModeChanged.macroMode: unknown enum value '\(macroModeRaw)'"
                    )
                )
            }
            macroMode = macroModeRaw
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "MacroModeListenerOnMacroModeChanged.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(macroMode, forKey: .macroMode)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["macroMode"] = macroMode
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the data capture context started observing.
    struct DataCaptureContextListenerOnObservationStarted: Codable {
        let licenseInfo: String?
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            licenseInfo: String? = nil,
            event: String
        ) {
            self.licenseInfo = licenseInfo
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "licenseInfo",
            "event",
        ]
        private static let eventAllowedValues: Set<String> = ["DataCaptureContextListener.onObservationStarted"]

        enum CodingKeys: String, CodingKey {
            case licenseInfo
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "DataCaptureContextListenerOnObservationStarted: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard container.contains(.licenseInfo) else {
                throw DecodingError.keyNotFound(
                    CodingKeys.licenseInfo,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription:
                            "DataCaptureContextListenerOnObservationStarted.licenseInfo: missing required property"
                    )
                )
            }
            licenseInfo = try container.decodeIfPresent(String.self, forKey: .licenseInfo)
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription:
                            "DataCaptureContextListenerOnObservationStarted.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if let licenseInfo {
                try container.encode(licenseInfo, forKey: .licenseInfo)
            } else {
                try container.encodeNil(forKey: .licenseInfo)
            }
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["licenseInfo"] = licenseInfo ?? NSNull()
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the data capture context's status changed. Also emitted synthetically
    /// by FrameworksDataCaptureContextListener.notifyCameraPermissionDenied() with a hand-built status
    /// JSON (code 1032).
    struct DataCaptureContextListenerOnStatusChanged: Codable {
        let status: String
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            status: String,
            event: String
        ) {
            self.status = status
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "status",
            "event",
        ]
        private static let eventAllowedValues: Set<String> = ["DataCaptureContextListener.onStatusChanged"]

        enum CodingKeys: String, CodingKey {
            case status
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "DataCaptureContextListenerOnStatusChanged: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            status = try container.decode(String.self, forKey: .status)
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription:
                            "DataCaptureContextListenerOnStatusChanged.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(status, forKey: .status)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["status"] = status
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the context's active frame source changed. Unlike
    /// FrameSourceListener.onStateChanged this reports the change itself rather than a state
    /// transition, so it is emitted even when neither camera changes state -- which is what makes a
    /// switch taken while the camera is off observable at all.
    struct DataCaptureContextListenerOnFrameSourceChanged: Codable {
        let cameraPosition: String?
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            cameraPosition: String? = nil,
            event: String
        ) {
            self.cameraPosition = cameraPosition
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "cameraPosition",
            "event",
        ]
        private static let cameraPositionAllowedValues: Set<String> = ["worldFacing", "userFacing", "unspecified"]
        private static let eventAllowedValues: Set<String> = ["DataCaptureContextListener.onFrameSourceChanged"]

        enum CodingKeys: String, CodingKey {
            case cameraPosition
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "DataCaptureContextListenerOnFrameSourceChanged: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let cameraPositionRaw = try container.decodeIfPresent(String.self, forKey: .cameraPosition)
            if let cameraPositionRaw {
                guard Self.cameraPositionAllowedValues.contains(cameraPositionRaw) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription:
                                "DataCaptureContextListenerOnFrameSourceChanged.cameraPosition: unknown enum value '\(cameraPositionRaw)'"
                        )
                    )
                }
            }
            cameraPosition = cameraPositionRaw
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription:
                            "DataCaptureContextListenerOnFrameSourceChanged.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(cameraPosition, forKey: .cameraPosition)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["cameraPosition"] = cameraPosition ?? NSNull()
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the data capture view's size changed.
    struct DataCaptureViewListenerOnSizeChanged: Codable {
        let viewId: Int
        let size: DataCaptureViewListenerOnSizeChangedSize
        let orientation: String
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            viewId: Int,
            size: DataCaptureViewListenerOnSizeChangedSize,
            orientation: String,
            event: String
        ) {
            self.viewId = viewId
            self.size = size
            self.orientation = orientation
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "viewId",
            "size",
            "orientation",
            "event",
        ]
        private static let orientationAllowedValues: Set<String> = [
            "unknown", "portrait", "portraitUpsideDown", "landscapeLeft", "landscapeRight",
        ]
        private static let eventAllowedValues: Set<String> = ["DataCaptureViewListener.onSizeChanged"]

        enum CodingKeys: String, CodingKey {
            case viewId
            case size
            case orientation
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "DataCaptureViewListenerOnSizeChanged: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            viewId = try container.decode(Int.self, forKey: .viewId)
            guard viewId >= Int(Int32.min), viewId <= Int(Int32.max) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "DataCaptureViewListenerOnSizeChanged.viewId: out of Int32 range"
                    )
                )
            }
            size = try container.decode(DataCaptureViewListenerOnSizeChangedSize.self, forKey: .size)
            let orientationRaw = try container.decode(String.self, forKey: .orientation)
            guard Self.orientationAllowedValues.contains(orientationRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription:
                            "DataCaptureViewListenerOnSizeChanged.orientation: unknown enum value '\(orientationRaw)'"
                    )
                )
            }
            orientation = orientationRaw
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "DataCaptureViewListenerOnSizeChanged.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(viewId, forKey: .viewId)
            try container.encode(size, forKey: .size)
            try container.encode(orientation, forKey: .orientation)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["viewId"] = viewId
            dict["size"] = size.toDictionary()
            dict["orientation"] = orientation
            dict["event"] = event
            return dict
        }
    }

    /// The new size of the view, in pixels. A genuine nested object, not a serialized JSON string:
    /// Android sends Int width/height, iOS sends CGFloat.
    struct DataCaptureViewListenerOnSizeChangedSize: Codable {
        let width: Double
        let height: Double

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            width: Double,
            height: Double
        ) {
            self.width = width
            self.height = height
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "width",
            "height",
        ]

        enum CodingKeys: String, CodingKey {
            case width
            case height
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "DataCaptureViewListenerOnSizeChangedSize: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            width = try container.decode(Double.self, forKey: .width)
            height = try container.decode(Double.self, forKey: .height)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(width, forKey: .width)
            try container.encode(height, forKey: .height)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["width"] = width
            dict["height"] = height
            return dict
        }
    }

    /// Notifies the listener that the focus gesture was performed.
    struct FocusGestureListenerOnFocusGesture: Codable {
        let viewId: Int
        let focusGesture: String
        let point: String
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            viewId: Int,
            focusGesture: String,
            point: String,
            event: String
        ) {
            self.viewId = viewId
            self.focusGesture = focusGesture
            self.point = point
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "viewId",
            "focusGesture",
            "point",
            "event",
        ]
        private static let eventAllowedValues: Set<String> = ["FocusGestureListener.onFocusGesture"]

        enum CodingKeys: String, CodingKey {
            case viewId
            case focusGesture
            case point
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "FocusGestureListenerOnFocusGesture: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            viewId = try container.decode(Int.self, forKey: .viewId)
            guard viewId >= Int(Int32.min), viewId <= Int(Int32.max) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "FocusGestureListenerOnFocusGesture.viewId: out of Int32 range"
                    )
                )
            }
            focusGesture = try container.decode(String.self, forKey: .focusGesture)
            point = try container.decode(String.self, forKey: .point)
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "FocusGestureListenerOnFocusGesture.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(viewId, forKey: .viewId)
            try container.encode(focusGesture, forKey: .focusGesture)
            try container.encode(point, forKey: .point)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["viewId"] = viewId
            dict["focusGesture"] = focusGesture
            dict["point"] = point
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the zoom-in gesture was performed.
    struct ZoomGestureListenerOnZoomInGesture: Codable {
        let viewId: Int
        let zoomGesture: String
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            viewId: Int,
            zoomGesture: String,
            event: String
        ) {
            self.viewId = viewId
            self.zoomGesture = zoomGesture
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "viewId",
            "zoomGesture",
            "event",
        ]
        private static let eventAllowedValues: Set<String> = ["ZoomGestureListener.onZoomInGesture"]

        enum CodingKeys: String, CodingKey {
            case viewId
            case zoomGesture
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "ZoomGestureListenerOnZoomInGesture: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            viewId = try container.decode(Int.self, forKey: .viewId)
            guard viewId >= Int(Int32.min), viewId <= Int(Int32.max) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "ZoomGestureListenerOnZoomInGesture.viewId: out of Int32 range"
                    )
                )
            }
            zoomGesture = try container.decode(String.self, forKey: .zoomGesture)
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "ZoomGestureListenerOnZoomInGesture.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(viewId, forKey: .viewId)
            try container.encode(zoomGesture, forKey: .zoomGesture)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["viewId"] = viewId
            dict["zoomGesture"] = zoomGesture
            dict["event"] = event
            return dict
        }
    }

    /// Notifies the listener that the zoom-out gesture was performed.
    struct ZoomGestureListenerOnZoomOutGesture: Codable {
        let viewId: Int
        let zoomGesture: String
        let event: String

        // Explicit memberwise init -- defining `init(from decoder:)` below suppresses Swift's
        // synthesized memberwise initializer, but emit sites need to build these payloads (not
        // just decode them), so both must coexist.
        init(
            viewId: Int,
            zoomGesture: String,
            event: String
        ) {
            self.viewId = viewId
            self.zoomGesture = zoomGesture
            self.event = event
        }

        // Built once per type rather than per decode -- see the per-property
        // `AllowedValues` sets below for the same rationale.
        private static let allowedKeys: Set<String> = [
            "viewId",
            "zoomGesture",
            "event",
        ]
        private static let eventAllowedValues: Set<String> = ["ZoomGestureListener.onZoomOutGesture"]

        enum CodingKeys: String, CodingKey {
            case viewId
            case zoomGesture
            case event
        }

        init(from decoder: Decoder) throws {
            let anyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in anyContainer.allKeys {
                guard Self.allowedKeys.contains(key.stringValue) else {
                    throw UnknownPropertyError(
                        message: "ZoomGestureListenerOnZoomOutGesture: unknown property '\(key.stringValue)'"
                    )
                }
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            viewId = try container.decode(Int.self, forKey: .viewId)
            guard viewId >= Int(Int32.min), viewId <= Int(Int32.max) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "ZoomGestureListenerOnZoomOutGesture.viewId: out of Int32 range"
                    )
                )
            }
            zoomGesture = try container.decode(String.self, forKey: .zoomGesture)
            let eventRaw = try container.decode(String.self, forKey: .event)
            guard Self.eventAllowedValues.contains(eventRaw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "ZoomGestureListenerOnZoomOutGesture.event: unknown enum value '\(eventRaw)'"
                    )
                )
            }
            event = eventRaw
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(viewId, forKey: .viewId)
            try container.encode(zoomGesture, forKey: .zoomGesture)
            try container.encode(event, forKey: .event)
        }

        // Dictionary projection for `Event.emit(on:payload: [String: Any])`
        // (frameworks/shared/ios/.../Event/Event.swift) -- a NULLABLE property keeps
        // its key, written as NSNull when nil: omitting it changed the emitted bytes
        // for payloads that previously rode through as raw JSON (SDC-33900), and a
        // strict parser accepts an explicit null but throws on a missing key
        // (SDC-33544). A non-nullable optional is omitted when nil, because the
        // decoder rejects an explicit null for it.
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            dict["viewId"] = viewId
            dict["zoomGesture"] = zoomGesture
            dict["event"] = event
            return dict
        }
    }
}
