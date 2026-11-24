/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

/// Unit tests for `DefaultsDriftComparator` itself (SDC-32173 review Major 2): the comparator
/// was previously exercised only end-to-end (one instrumented test against a real SDK dump),
/// which cannot distinguish "no drift" from "comparator too permissive". These cases are
/// mirrored byte-for-byte in the Kotlin counterpart (`DefaultsDriftComparatorTest.kt`) so both
/// platforms are asserted to agree on the same fixtures, not just individually "pass".
final class DefaultsDriftComparatorTests: XCTestCase {

    private func field(
        _ type: String,
        _ value: Any?,
        typeOnly: Bool = false
    )
        -> DefaultsDriftComparator.ExpectedField
    {
        DefaultsDriftComparator.ExpectedField(type: type, value: value, typeOnly: typeOnly)
    }

    func testMissingKeyIsReportedAsMissingFromDump() {
        let expected = ["Core.foo": field("string", "bar")]
        let actual: [String: Any?] = [:]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].contains("MISSING FROM DUMP"))
        XCTAssertTrue(failures[0].contains("Core.foo"))
    }

    func testExtraKeyIsReportedAsExtraInDump() {
        let expected: [String: DefaultsDriftComparator.ExpectedField] = [:]
        let actual: [String: Any?] = ["Core.foo": "bar"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].contains("EXTRA IN DUMP"))
        XCTAssertTrue(failures[0].contains("Core.foo"))
    }

    func testValueDriftIsReported() {
        let expected = ["Core.foo": field("string", "bar")]
        let actual: [String: Any?] = ["Core.foo": "baz"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].contains("VALUE DRIFT"))
    }

    func testTypeOnlyToleratesNullAndEmptyWithoutCheckingShape() {
        let expected = [
            "Core.dyn1": field("array", nil, typeOnly: true),
            "Core.dyn2": field("object", nil, typeOnly: true),
        ]
        let actual: [String: Any?] = [
            "Core.dyn1": nil,
            "Core.dyn2": [String: Any](),
        ]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty)
    }

    func testTypeOnlyReportsMismatchWhenARealValueHasTheWrongShape() {
        let expected = ["Core.dyn": field("array", nil, typeOnly: true)]
        let actual: [String: Any?] = ["Core.dyn": "not an array"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].contains("DYNAMIC TYPE MISMATCH"))
    }

    func testJsonStringEncodedObjectIsUnwrappedBeforeComparing() {
        let expected = ["Core.foo": field("object", ["a": 1])]
        let actual: [String: Any?] = ["Core.foo": "{\"a\":1}"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty)
    }

    func testColorNormalisesHashPrefixAndCase() {
        let expected = ["Core.color": field("color", "#AABBCCDD")]
        let actual: [String: Any?] = ["Core.color": "aabbccdd"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty)
    }

    // SDC-33331: twins of the Kotlin cases in DefaultsDriftComparatorTest.kt, over the SAME
    // fixtures. Nothing checks the mirrors automatically and they diverged three times during
    // SDC-32173 - keep them in lockstep.

    func testColourInsideAnObjectIsCanonicalisedNotReportedAsDrift() {
        func brush(_ color: String) -> [String: Any] {
            ["fill": ["color": color], "stroke": ["width": 1]]
        }
        let expected = ["Core.brush": field("object", brush("#0061FFFF"))]
        let actual: [String: Any?] = ["Core.brush": brush("0061ffff")]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty, "brush colour casing is not drift: \(failures)")
    }

    func testANonColourStringInsideAnObjectStillComparesExactly() {
        // Guards the canonicalisation above from swallowing real drift: only hex-COLOUR
        // shaped strings are normalised, so a resource name is still compared verbatim.
        let expected = ["Core.sound": field("object", ["resource": "sc_click"])]
        let actual: [String: Any?] = ["Core.sound": ["resource": "SC_CLICK"]]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures.first?.hasPrefix("VALUE DRIFT") == true)
    }

    func testFlattenDescendsIntoAJsonStringSubTreeWhenTheSotDeclaresSubPaths() {
        let expectedPaths: Set<String> = ["Barcode.Ar.feedback.scanned", "Barcode.Ar.feedback.tapped"]
        let dump: [String: Any?] = [
            "Ar": ["feedback": "{\"scanned\":{\"sound\":\"a\"},\"tapped\":{\"sound\":\"b\"}}"]
        ]

        let flat = DefaultsDriftComparator.flatten(
            dump: dump,
            modulePrefix: "Barcode",
            expectedPaths: expectedPaths
        )

        XCTAssertEqual(flat["Barcode.Ar.feedback.scanned"] as? [String: String], ["sound": "a"])
        XCTAssertEqual(flat["Barcode.Ar.feedback.tapped"] as? [String: String], ["sound": "b"])
        XCTAssertNil(flat["Barcode.Ar.feedback"] ?? nil, "the raw string must not also be emitted")
    }

    func testFlattenLeavesAJsonStringLeafAloneWhenTheSotDeclaresItWhole() {
        let expectedPaths: Set<String> = ["Barcode.Ar.feedback"]
        let dump: [String: Any?] = ["Ar": ["feedback": "{\"scanned\":1}"]]

        let flat = DefaultsDriftComparator.flatten(
            dump: dump,
            modulePrefix: "Barcode",
            expectedPaths: expectedPaths
        )

        XCTAssertEqual(flat["Barcode.Ar.feedback"] as? String, "{\"scanned\":1}")
    }

    func testFlattenLeavesAnOrdinaryStringLeafAlone() {
        let flat = DefaultsDriftComparator.flatten(
            dump: ["name": "not json"],
            modulePrefix: "Core",
            expectedPaths: ["Core.name"]
        )

        XCTAssertEqual(flat["Core.name"] as? String, "not json")
    }

    func testFloatEpsilonToleratesRoundTripError() {
        let expected = ["Core.ratio": field("number", 0.8)]
        let actual: [String: Any?] = ["Core.ratio": 0.800000011920929]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty)
    }

    func testMismatchedDynamicTypeIsReportedAsDriftNotSilentlyEqual() {
        // Expected a String (per SoT authoring), actual dump produced an NSNumber - a
        // real type-change drift (SDC-32173 review Major 1). Previously fell through to
        // the description-based fallback and compared EQUAL; must now fail closed,
        // mirroring the Kotlin comparator's plain `==` fallback.
        let expected = ["Core.foo": field("string", "42")]
        let actual: [String: Any?] = ["Core.foo": NSNumber(value: 42)]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].contains("VALUE DRIFT"))
    }

    func testNullOnBothSidesIsNotDrift() {
        // JSONSerialization decodes a JSON null as NSNull, not Swift nil, on BOTH the
        // snapshot and the dump side - so a nullable default that is legitimately null
        // everywhere arrives as (NSNull, NSNull). Must not trip the fail-closed default.
        let expected = ["Core.foo": field("string", NSNull())]
        let actual: [String: Any?] = ["Core.foo": NSNull()]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty, "null-on-both-sides must not report drift: \(failures)")
    }

    // SDC-33331 - `runtimeOnlyPrefixes`: knowingly-unmodelled runtime subtrees declared in
    // the SoT (group-level `runtimeOnlyPrefix`) and stamped into the snapshot by the
    // generator. Same four fixtures exist in DefaultsDriftComparatorTest.kt - the two
    // mirrors diverged three times during SDC-32173, so they are kept in lockstep.

    func testARuntimeOnlyPrefixSuppressesExtraForTheKeyEqualToThePrefix() {
        // Several declarations name ONE runtime leaf, not a subtree (e.g.
        // Barcode.Barcode.SymbologyDescriptions) - an equal-to-prefix key must be suppressed.
        let expected: [String: DefaultsDriftComparator.ExpectedField] = [:]
        let actual: [String: Any?] = ["Core.engineMeta": "opaque"]

        let failures = DefaultsDriftComparator.compare(
            actual: actual,
            expected: expected,
            scopePrefixes: ["Core"],
            runtimeOnlyPrefixes: ["Core.engineMeta"]
        )

        XCTAssertTrue(failures.isEmpty, "key equal to the prefix must be suppressed: \(failures)")
    }

    func testARuntimeOnlyPrefixSuppressesExtraForKeysBelowIt() {
        let expected: [String: DefaultsDriftComparator.ExpectedField] = [:]
        let actual: [String: Any?] = [
            "Core.engineMeta.ean13.checksums": 1,
            "Core.engineMeta.code39.extensions": "x",
        ]

        let failures = DefaultsDriftComparator.compare(
            actual: actual,
            expected: expected,
            scopePrefixes: ["Core"],
            runtimeOnlyPrefixes: ["Core.engineMeta"]
        )

        XCTAssertTrue(failures.isEmpty, "keys below the prefix must be suppressed: \(failures)")
    }

    func testADeclaredKeyUnderARuntimeOnlyPrefixIsStillValueCompared() {
        // The suppression is EXTRA-only: declaring a field under a runtime-only subtree
        // opts that one path back into full comparison, so drift under it is still caught.
        let expected = ["Core.engineMeta.known": field("string", "bar")]
        let actual: [String: Any?] = ["Core.engineMeta.known": "baz"]

        let failures = DefaultsDriftComparator.compare(
            actual: actual,
            expected: expected,
            scopePrefixes: ["Core"],
            runtimeOnlyPrefixes: ["Core.engineMeta"]
        )

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].contains("VALUE DRIFT"))
    }

    // SDC-33331 - `knownDefect`: a per-path SoT declaration that the runtime EMITTER is wrong
    // here, stating the exact wrong value. The same five fixtures exist in
    // DefaultsDriftComparatorTest.kt - keep the two mirrors in lockstep.

    private func defect(
        _ runtimeValue: Any?,
        ticket: String? = "SDC-33468"
    ) -> DefaultsDriftComparator.KnownDefect {
        DefaultsDriftComparator.KnownDefect(
            reason: "emitter truncates the alpha byte (color.hh:66-72)",
            ticket: ticket,
            runtimeValue: runtimeValue
        )
    }

    func testADeclaredKnownDefectPresentExactlyAsDocumentedIsNotAFailure() {
        let expected = [
            "Core.foo": DefaultsDriftComparator.ExpectedField(
                type: "string",
                value: "Restart",
                typeOnly: false,
                knownDefect: defect("restart")
            )
        ]
        let actual: [String: Any?] = ["Core.foo": "restart"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty, "a documented defect must not fail: \(failures)")
    }

    func testADeclaredKnownDefectThatGotFixedFailsSoTheDeclarationCannotRot() {
        // The anti-rot property: once the emitter is fixed, the SoT declaration is stale and
        // would silently exempt this path from comparison forever. Fail, and say what to do.
        let expected = [
            "Core.foo": DefaultsDriftComparator.ExpectedField(
                type: "string",
                value: "Restart",
                typeOnly: false,
                knownDefect: defect("restart", ticket: "SDC-33468")
            )
        ]
        let actual: [String: Any?] = ["Core.foo": "Restart"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].hasPrefix("KNOWN DEFECT APPEARS FIXED"))
        XCTAssertTrue(failures[0].contains("Core.foo"))
        XCTAssertTrue(failures[0].contains("SDC-33468"))
        XCTAssertTrue(failures[0].contains("Remove the knownDefect declaration"))
    }

    func testAValueMatchingNeitherTheSotNorTheDeclaredDefectIsDriftNamingAllThree() {
        let expected = [
            "Core.foo": DefaultsDriftComparator.ExpectedField(
                type: "string",
                value: "Restart",
                typeOnly: false,
                knownDefect: defect("restart", ticket: nil)
            )
        ]
        let actual: [String: Any?] = ["Core.foo": "RESTART"]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].hasPrefix("VALUE DRIFT"))
        XCTAssertTrue(failures[0].contains("NEITHER"))
        XCTAssertTrue(failures[0].contains("no ticket filed"))
        // All three values printed: SoT, declared defect, dump.
        XCTAssertTrue(failures[0].contains("Restart"))
        XCTAssertTrue(failures[0].contains("restart"))
        XCTAssertTrue(failures[0].contains("RESTART"))
    }

    func testAKnownDefectValueIsComparedWithTheSameColourCanonicalisation() {
        // The declared wrong value goes through canonicalColor/deepEquals exactly as the SoT
        // value does, so a brush defect can be declared in either colour spelling.
        func brush(_ color: String) -> [String: Any] { ["fill": ["color": color]] }
        let expected = [
            "Core.brush": DefaultsDriftComparator.ExpectedField(
                type: "object",
                value: brush("#0062FFE6"),
                typeOnly: false,
                knownDefect: defect(brush("#0062FFE5"))
            )
        ]
        let actual: [String: Any?] = ["Core.brush": brush("0062ffe5")]

        let failures = DefaultsDriftComparator.compare(actual: actual, expected: expected, scopePrefixes: ["Core"])

        XCTAssertTrue(failures.isEmpty, "defect value must canonicalise too: \(failures)")
    }

    func testLoadExpectedReadsAPlatformScopedDeclarationOnlyWhereTheSnapshotCarriesIt() throws {
        // `platforms` is applied by the GENERATOR: a declaration scoped to one platform is
        // simply absent from the other platform's snapshot, and that path then compares
        // normally. Both shapes are parsed here, including the optional 'ticket'.
        let withDefect = """
            {"fields": {"Core.foo": {"type": "bool", "value": false,
              "knownDefect": {"reason": "iOS copy-paste bug", "runtimeValue": true}}}}
            """
        let withoutDefect = "{\"fields\": {\"Core.foo\": {\"type\": \"bool\", \"value\": false}}}"

        let ios = try DefaultsDriftComparator.loadExpected(data: Data(withDefect.utf8))
        let android = try DefaultsDriftComparator.loadExpected(data: Data(withoutDefect.utf8))

        XCTAssertEqual(ios["Core.foo"]?.knownDefect?.runtimeValue as? Bool, true)
        XCTAssertNil(ios["Core.foo"]?.knownDefect?.ticket)
        XCTAssertNil(android["Core.foo"]?.knownDefect)

        let actual: [String: Any?] = ["Core.foo": true]
        XCTAssertTrue(
            DefaultsDriftComparator.compare(actual: actual, expected: ios, scopePrefixes: ["Core"]).isEmpty
        )
        XCTAssertEqual(
            DefaultsDriftComparator.compare(actual: actual, expected: android, scopePrefixes: ["Core"]).count,
            1
        )
    }

    func testAKeyNotUnderAnyRuntimeOnlyPrefixIsStillReportedAsExtra() {
        // Guards the suppression from widening into a blanket "ignore unknown keys":
        // the SoT-first rule still holds everywhere a prefix was not declared.
        let expected: [String: DefaultsDriftComparator.ExpectedField] = [:]
        let actual: [String: Any?] = ["Core.somethingNew": "value"]

        let failures = DefaultsDriftComparator.compare(
            actual: actual,
            expected: expected,
            scopePrefixes: ["Core"],
            runtimeOnlyPrefixes: ["Core.engineMeta"]
        )

        XCTAssertEqual(failures.count, 1)
        XCTAssertTrue(failures[0].contains("EXTRA IN DUMP"))
        XCTAssertTrue(failures[0].contains("Core.somethingNew"))
    }
}
