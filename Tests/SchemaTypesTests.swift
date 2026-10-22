/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

// THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
// Generator: scripts/bridge_generator/generate.py
// Schema: scripts/bridge_generator/schemas/core.json
//
// Fixture-driven round-trip tests: every fixture under
// serialization/tests/<module>/<name>/valid/ must decode without throwing
// (and its re-encoded/re-decoded form must decode too); every fixture
// under .../invalid/ must throw UNLESS the validation keyword that rejects
// it (minimum, pattern, oneOf, ...) is outside the set the hand-rolled
// validator supports, in which case the test is skipped (`XCTSkip`) rather
// than asserting a throw the code can't produce.

import XCTest

@testable import ScanditFrameworksCore

final class SchemaTypesTest: XCTestCase {

    func testSequenceFrameSourceAcceptsValid_full_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "type": "sequence",
              "id": "sequence-frame-src-1",
              "position": "userFacing",
              "lensPosition": 0.5,
              "desiredState": "on"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: reEncoded))
    }

    func testSequenceFrameSourceAcceptsValid_minimal_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "type": "sequence",
              "position": "worldFacing"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: reEncoded))
    }

    func testSequenceFrameSourceRejectsInvalid_missing_position_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "type": "sequence"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: raw))
    }

    func testSequenceFrameSourceRejectsInvalid_missing_type_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "position": "worldFacing"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: raw))
    }

    func testSequenceFrameSourceRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "type": "sequence",
              "position": "worldFacing",
              "unknown": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: raw)) { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testSequenceFrameSourceRejectsInvalid_wrong_type_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "type": "image",
              "position": "worldFacing"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.SequenceFrameSource.self, from: raw))
    }

    func testFrameSourceListenerOnStateChangedAcceptsValid_camera_position_absent_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "starting",
              "event": "FrameSourceListener.onStateChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: reEncoded))
    }

    func testFrameSourceListenerOnStateChangedAcceptsValid_camera_position_null_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "off",
              "cameraPosition": null,
              "event": "FrameSourceListener.onStateChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: reEncoded))
    }

    func testFrameSourceListenerOnStateChangedAcceptsValid_camera_position_present_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "on",
              "cameraPosition": "worldFacing",
              "event": "FrameSourceListener.onStateChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: reEncoded))
    }

    func testFrameSourceListenerOnStateChangedRejectsInvalid_missing_state_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "worldFacing",
              "event": "FrameSourceListener.onStateChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: raw))
    }

    func testFrameSourceListenerOnStateChangedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "on",
              "cameraPosition": "worldFacing",
              "event": "FrameSourceListener.onStateChanged",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: raw)) {
            error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testFrameSourceListenerOnStateChangedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "on",
              "cameraPosition": "worldFacing",
              "event": "FrameSourceListener.onStateChanged.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: raw))
    }

    func testFrameSourceListenerOnStateChangedRejectsInvalid_wrong_type_state_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "notARealState",
              "cameraPosition": "worldFacing",
              "event": "FrameSourceListener.onStateChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FrameSourceListenerOnStateChanged.self, from: raw))
    }

    func testTorchListenerOnTorchStateChangedAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "auto",
              "event": "TorchListener.onTorchStateChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.TorchListenerOnTorchStateChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.TorchListenerOnTorchStateChanged.self, from: reEncoded))
    }

    func testTorchListenerOnTorchStateChangedRejectsInvalid_missing_state_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "event": "TorchListener.onTorchStateChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.TorchListenerOnTorchStateChanged.self, from: raw))
    }

    func testTorchListenerOnTorchStateChangedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "on",
              "event": "TorchListener.onTorchStateChanged",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.TorchListenerOnTorchStateChanged.self, from: raw)) {
            error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testTorchListenerOnTorchStateChangedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "on",
              "event": "TorchListener.onTorchStateChanged.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.TorchListenerOnTorchStateChanged.self, from: raw))
    }

    func testTorchListenerOnTorchStateChangedRejectsInvalid_wrong_type_state_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "state": "notARealState",
              "event": "TorchListener.onTorchStateChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.TorchListenerOnTorchStateChanged.self, from: raw))
    }

    func testZoomListenerOnZoomLevelChangedAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "oldZoomLevel": 1.0,
              "newZoomLevel": 2.5,
              "event": "ZoomListener.onZoomLevelChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.ZoomListenerOnZoomLevelChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.ZoomListenerOnZoomLevelChanged.self, from: reEncoded))
    }

    func testZoomListenerOnZoomLevelChangedRejectsInvalid_missing_newZoomLevel_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "oldZoomLevel": 1.0,
              "event": "ZoomListener.onZoomLevelChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomListenerOnZoomLevelChanged.self, from: raw))
    }

    func testZoomListenerOnZoomLevelChangedRejectsInvalid_missing_oldZoomLevel_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "newZoomLevel": 2.5,
              "event": "ZoomListener.onZoomLevelChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomListenerOnZoomLevelChanged.self, from: raw))
    }

    func testZoomListenerOnZoomLevelChangedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "oldZoomLevel": 1.0,
              "newZoomLevel": 2.5,
              "event": "ZoomListener.onZoomLevelChanged",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomListenerOnZoomLevelChanged.self, from: raw)) {
            error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testZoomListenerOnZoomLevelChangedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "oldZoomLevel": 1.0,
              "newZoomLevel": 2.5,
              "event": "ZoomListener.onZoomLevelChanged.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomListenerOnZoomLevelChanged.self, from: raw))
    }

    func testZoomListenerOnZoomLevelChangedRejectsInvalid_wrong_type_oldZoomLevel_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "oldZoomLevel": "not-a-number",
              "newZoomLevel": 2.5,
              "event": "ZoomListener.onZoomLevelChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomListenerOnZoomLevelChanged.self, from: raw))
    }

    func testMacroModeListenerOnMacroModeChangedAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "macroMode": "auto",
              "event": "MacroModeListener.onMacroModeChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.MacroModeListenerOnMacroModeChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.MacroModeListenerOnMacroModeChanged.self, from: reEncoded)
        )
    }

    func testMacroModeListenerOnMacroModeChangedRejectsInvalid_missing_macroMode_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "event": "MacroModeListener.onMacroModeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.MacroModeListenerOnMacroModeChanged.self, from: raw))
    }

    func testMacroModeListenerOnMacroModeChangedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "macroMode": "on",
              "event": "MacroModeListener.onMacroModeChanged",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.MacroModeListenerOnMacroModeChanged.self, from: raw))
        { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testMacroModeListenerOnMacroModeChangedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "macroMode": "on",
              "event": "MacroModeListener.onMacroModeChanged.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.MacroModeListenerOnMacroModeChanged.self, from: raw))
    }

    func testMacroModeListenerOnMacroModeChangedRejectsInvalid_wrong_type_macroMode_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "macroMode": "notARealMode",
              "event": "MacroModeListener.onMacroModeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.MacroModeListenerOnMacroModeChanged.self, from: raw))
    }

    func testDataCaptureContextListenerOnObservationStartedAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "licenseInfo": "{\"expirationDateStatus\":\"perpetual\"}",
              "event": "DataCaptureContextListener.onObservationStarted"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(
            SchemaTypes.DataCaptureContextListenerOnObservationStarted.self,
            from: raw
        )
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnObservationStarted.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnObservationStartedAcceptsValid_null_license_info_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "licenseInfo": null,
              "event": "DataCaptureContextListener.onObservationStarted"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(
            SchemaTypes.DataCaptureContextListenerOnObservationStarted.self,
            from: raw
        )
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnObservationStarted.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnObservationStartedRejectsInvalid_missing_licenseInfo_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "event": "DataCaptureContextListener.onObservationStarted"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnObservationStarted.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnObservationStartedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "licenseInfo": null,
              "event": "DataCaptureContextListener.onObservationStarted",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnObservationStarted.self, from: raw)
        ) { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testDataCaptureContextListenerOnObservationStartedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "licenseInfo": null,
              "event": "DataCaptureContextListener.onObservationStarted.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnObservationStarted.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnObservationStartedRejectsInvalid_wrong_type_licenseInfo_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "licenseInfo": 123,
              "event": "DataCaptureContextListener.onObservationStarted"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnObservationStarted.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnStatusChangedAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "status": "{\"code\":0,\"isValid\":true,\"message\":\"\"}",
              "event": "DataCaptureContextListener.onStatusChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnStatusChangedAcceptsValid_camera_permission_denied_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "status": "{\"code\":1032,\"isValid\":true,\"message\":\"Required resource access denied. Camera permission is not granted.\"}",
              "event": "DataCaptureContextListener.onStatusChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnStatusChangedRejectsInvalid_missing_status_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "event": "DataCaptureContextListener.onStatusChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnStatusChangedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "status": "{\"code\":0,\"isValid\":true,\"message\":\"\"}",
              "event": "DataCaptureContextListener.onStatusChanged",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: raw)
        ) { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testDataCaptureContextListenerOnStatusChangedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "status": "{\"code\":0,\"isValid\":true,\"message\":\"\"}",
              "event": "DataCaptureContextListener.onStatusChanged.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnStatusChangedRejectsInvalid_wrong_type_status_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "status": 123,
              "event": "DataCaptureContextListener.onStatusChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnStatusChanged.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedAcceptsValid_camera_position_absent_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "event": "DataCaptureContextListener.onFrameSourceChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(
            SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self,
            from: raw
        )
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedAcceptsValid_camera_position_null_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": null,
              "event": "DataCaptureContextListener.onFrameSourceChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(
            SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self,
            from: raw
        )
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedAcceptsValid_camera_position_unspecified_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "unspecified",
              "event": "DataCaptureContextListener.onFrameSourceChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(
            SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self,
            from: raw
        )
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedAcceptsValid_camera_position_user_facing_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "userFacing",
              "event": "DataCaptureContextListener.onFrameSourceChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(
            SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self,
            from: raw
        )
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedAcceptsValid_camera_position_world_facing_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "worldFacing",
              "event": "DataCaptureContextListener.onFrameSourceChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(
            SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self,
            from: raw
        )
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedRejectsInvalid_missing_event_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "worldFacing"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedRejectsInvalid_unknown_camera_position_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "rearFacing",
              "event": "DataCaptureContextListener.onFrameSourceChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "worldFacing",
              "event": "DataCaptureContextListener.onFrameSourceChanged",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: raw)
        ) { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testDataCaptureContextListenerOnFrameSourceChangedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": "worldFacing",
              "event": "DataCaptureContextListener.onFrameSourceChanged.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: raw)
        )
    }

    func testDataCaptureContextListenerOnFrameSourceChangedRejectsInvalid_wrong_type_camera_position_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "cameraPosition": 1,
              "event": "DataCaptureContextListener.onFrameSourceChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(SchemaTypes.DataCaptureContextListenerOnFrameSourceChanged.self, from: raw)
        )
    }

    func testDataCaptureViewListenerOnSizeChangedAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": 1080.0, "height": 1920.0 },
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureViewListenerOnSizeChangedAcceptsValid_orientation_unknown_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": 1080.0, "height": 1920.0 },
              "orientation": "unknown",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: reEncoded)
        )
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_missing_orientation_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": 1080.0, "height": 1920.0 },
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_missing_size_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_missing_size_width_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "height": 1920.0 },
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_missing_viewId_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "size": { "width": 1080.0, "height": 1920.0 },
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": 1080.0, "height": 1920.0 },
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
        { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_unknown_property_in_size_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": 1080.0, "height": 1920.0, "depth": 1.0 },
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
        { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": 1080.0, "height": 1920.0 },
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_wrong_type_orientation_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": 1080.0, "height": 1920.0 },
              "orientation": "notARealOrientation",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
    }

    func testDataCaptureViewListenerOnSizeChangedRejectsInvalid_wrong_type_size_width_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "size": { "width": "1080", "height": 1920.0 },
              "orientation": "portrait",
              "event": "DataCaptureViewListener.onSizeChanged"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewListenerOnSizeChanged.self, from: raw))
    }

    func testFocusGestureListenerOnFocusGestureAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "focusGesture": "{\"type\":\"tapToFocus\",\"showUIIndicator\":true}",
              "point": "{\"x\":{\"value\":0.5,\"unit\":\"fraction\"},\"y\":{\"value\":0.5,\"unit\":\"fraction\"}}",
              "event": "FocusGestureListener.onFocusGesture"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.FocusGestureListenerOnFocusGesture.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.FocusGestureListenerOnFocusGesture.self, from: reEncoded))
    }

    func testFocusGestureListenerOnFocusGestureRejectsInvalid_missing_focusGesture_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "point": "{\"x\":{\"value\":0.5,\"unit\":\"fraction\"},\"y\":{\"value\":0.5,\"unit\":\"fraction\"}}",
              "event": "FocusGestureListener.onFocusGesture"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FocusGestureListenerOnFocusGesture.self, from: raw))
    }

    func testFocusGestureListenerOnFocusGestureRejectsInvalid_missing_point_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "focusGesture": "{\"type\":\"tapToFocus\",\"showUIIndicator\":true}",
              "event": "FocusGestureListener.onFocusGesture"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FocusGestureListenerOnFocusGesture.self, from: raw))
    }

    func testFocusGestureListenerOnFocusGestureRejectsInvalid_missing_viewId_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "focusGesture": "{\"type\":\"tapToFocus\",\"showUIIndicator\":true}",
              "point": "{\"x\":{\"value\":0.5,\"unit\":\"fraction\"},\"y\":{\"value\":0.5,\"unit\":\"fraction\"}}",
              "event": "FocusGestureListener.onFocusGesture"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FocusGestureListenerOnFocusGesture.self, from: raw))
    }

    func testFocusGestureListenerOnFocusGestureRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "focusGesture": "{\"type\":\"tapToFocus\",\"showUIIndicator\":true}",
              "point": "{\"x\":{\"value\":0.5,\"unit\":\"fraction\"},\"y\":{\"value\":0.5,\"unit\":\"fraction\"}}",
              "event": "FocusGestureListener.onFocusGesture",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FocusGestureListenerOnFocusGesture.self, from: raw)) {
            error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testFocusGestureListenerOnFocusGestureRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "focusGesture": "{\"type\":\"tapToFocus\",\"showUIIndicator\":true}",
              "point": "{\"x\":{\"value\":0.5,\"unit\":\"fraction\"},\"y\":{\"value\":0.5,\"unit\":\"fraction\"}}",
              "event": "FocusGestureListener.onFocusGesture.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.FocusGestureListenerOnFocusGesture.self, from: raw))
    }

    func testZoomGestureListenerOnZoomInGestureAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomInGesture"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomInGesture.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomInGesture.self, from: reEncoded))
    }

    func testZoomGestureListenerOnZoomInGestureRejectsInvalid_missing_viewId_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomInGesture"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomInGesture.self, from: raw))
    }

    func testZoomGestureListenerOnZoomInGestureRejectsInvalid_missing_zoomGesture_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "event": "ZoomGestureListener.onZoomInGesture"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomInGesture.self, from: raw))
    }

    func testZoomGestureListenerOnZoomInGestureRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomInGesture",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomInGesture.self, from: raw)) {
            error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testZoomGestureListenerOnZoomInGestureRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomInGesture.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomInGesture.self, from: raw))
    }

    func testZoomGestureListenerOnZoomOutGestureAcceptsValid_basic_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomOutGesture"
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomOutGesture.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(
            try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomOutGesture.self, from: reEncoded)
        )
    }

    func testZoomGestureListenerOnZoomOutGestureRejectsInvalid_missing_viewId_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomOutGesture"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomOutGesture.self, from: raw))
    }

    func testZoomGestureListenerOnZoomOutGestureRejectsInvalid_missing_zoomGesture_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "event": "ZoomGestureListener.onZoomOutGesture"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomOutGesture.self, from: raw))
    }

    func testZoomGestureListenerOnZoomOutGestureRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomOutGesture",
              "unknownProperty": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomOutGesture.self, from: raw))
        { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testZoomGestureListenerOnZoomOutGestureRejectsInvalid_wrong_event_const_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 1,
              "zoomGesture": "{\"type\":\"swipeToZoom\"}",
              "event": "ZoomGestureListener.onZoomOutGesture.wrongEventName"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.ZoomGestureListenerOnZoomOutGesture.self, from: raw))
    }

    func testDataCaptureViewPayloadAcceptsValid_defaults_only_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {}
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: reEncoded))
    }

    func testDataCaptureViewPayloadAcceptsValid_full_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "pointOfInterest": {"x": {"value": 0.5, "unit": "fraction"}, "y": {"value": 0.5, "unit": "fraction"}},
              "scanAreaMargins": {
                "left":   {"value": 0, "unit": "dip"},
                "top":    {"value": 0, "unit": "dip"},
                "right":  {"value": 0, "unit": "dip"},
                "bottom": {"value": 0, "unit": "dip"}
              },
              "logoAnchor": "bottomRight",
              "logoOffset": {"x": {"value": 0, "unit": "dip"}, "y": {"value": 0, "unit": "dip"}},
              "logoHidden": false,
              "logoStyle": "extended",
              "overlays": [],
              "controls": [],
              "focusGesture": {"type": "tapToFocus", "showUIIndicator": true},
              "zoomGestures": [{"type": "swipeToZoom"}]
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: reEncoded))
    }

    func testDataCaptureViewPayloadAcceptsValid_nested_view_with_parent_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 4,
              "parentId": 1
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: reEncoded))
    }

    func testDataCaptureViewPayloadAcceptsValid_null_gestures_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 2,
              "focusGesture": null,
              "zoomGesture": null
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: reEncoded))
    }

    func testDataCaptureViewPayloadAcceptsValid_with_properties_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "properties": {
                "logoHidden": true,
                "stopVideoTracksOnVisibilityChange": false,
                "customKey": 42
              }
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: reEncoded))
    }

    func testDataCaptureViewPayloadAcceptsValid_with_view_id_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 3
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: reEncoded))
    }

    func testDataCaptureViewPayloadAcceptsValid_with_zoom_notification_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "shouldShowZoomNotification": false
            }
            """#.utf8
        )
        let parsed = try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)
        let reEncoded = try JSONEncoder().encode(parsed)
        XCTAssertNoThrow(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: reEncoded))
    }

    func testDataCaptureViewPayloadRejectsInvalid_invalid_logo_anchor_enum_json() throws {
        throw XCTSkip("unenforceable keyword: enum (on generator-omitted property 'logoAnchor')")
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "logoAnchor": "middleCenter"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw))
    }

    func testDataCaptureViewPayloadRejectsInvalid_invalid_logo_style_enum_json() throws {
        throw XCTSkip("unenforceable keyword: enum (on generator-omitted property 'logoStyle')")
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "logoStyle": "full"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw))
    }

    func testDataCaptureViewPayloadRejectsInvalid_non_integer_view_id_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": 3.5
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw))
    }

    func testDataCaptureViewPayloadRejectsInvalid_unknown_property_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "logoHidden": false,
              "notAValidKey": true
            }
            """#.utf8
        )
        // Asserts the TYPE: the unknown-key class must surface as core's one shared
        // `UnknownPropertyError`, so a cross-module catch keeps matching.
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw)) { error in
            XCTAssertTrue(error is UnknownPropertyError, "expected UnknownPropertyError, got \(error)")
        }
    }

    func testDataCaptureViewPayloadRejectsInvalid_wrong_type_logo_hidden_json() throws {
        throw XCTSkip("unenforceable keyword: type (on generator-omitted property 'logoHidden')")
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "logoHidden": "yes"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw))
    }

    func testDataCaptureViewPayloadRejectsInvalid_wrong_type_properties_json() throws {
        throw XCTSkip("unenforceable keyword: type (on generator-omitted property 'properties')")
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "properties": "not-an-object"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw))
    }

    func testDataCaptureViewPayloadRejectsInvalid_wrong_type_view_id_json() throws {
        // Raw string literal (#"""..."""#): a plain Swift multi-line literal processes
        // backslash escapes, so a fixture carrying an embedded JSON string (any property
        // with contentMediaType: application/json) would have its \" collapsed to a bare "
        // and stop being valid JSON. Raw literals keep the fixture bytes verbatim.
        let raw = Data(
            #"""
            {
              "viewId": "3"
            }
            """#.utf8
        )
        XCTAssertThrowsError(try JSONDecoder().decode(SchemaTypes.DataCaptureViewPayload.self, from: raw))
    }
}
