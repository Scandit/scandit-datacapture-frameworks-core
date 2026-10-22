/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore
import XCTest

@testable import ScanditFrameworksCore

/// Layer-2 defaults-drift test for the Core module (SDC-32173, DESIGN.md section 4)
/// - the iOS mirror of `CoreDefaultsDriftTest.kt`
/// (`frameworks/shared/android/scandit-datacapture-frameworks-core/src/androidTest/.../defaults/CoreDefaultsDriftTest.kt`).
/// Constructs the real `CoreWideDefaults.shared` (the test-only wide builder) (backed by real `ScanditCaptureCore` SDK
/// objects, same as `ZoomSwitchControlDefaultsTests`/`MacroModeControlDefaultsTests`)
/// and compares its `toEncodable()` dump against the committed
/// `expected_defaults_ios.json` snapshot.
///
/// Only **Core** is enrolled in the drift harness today
/// (`scripts/defaults_generator/enrollment.py`); Barcode/Id/Label reconciliation is
/// SDC-33331.
final class CoreDefaultsDriftTests: XCTestCase {

    /// `Fixtures/expected_defaults_ios.json` is a committed symlink to the generator's real
    /// output at `scripts/defaults_generator/defaults/generated/` (SDC-32173 review: the
    /// prior `#filePath`-based lookup only worked when the test ran from this exact
    /// checkout - not from a bundle built elsewhere). Declared as a `.copy()` resource in
    /// Package.swift, so `Bundle.module` finds it regardless of the test runner's working
    /// directory or where the bundle was built - one committed file, no duplicate.
    private static func expectedDefaultsURL() throws -> URL {
        try XCTUnwrap(
            Bundle.module.url(forResource: "expected_defaults_ios", withExtension: "json"),
            "could not locate expected_defaults_ios.json in the test bundle - "
                + "run scripts/defaults_generator/generate.py, then check "
                + "Tests/Fixtures/expected_defaults_ios.json is still a valid symlink"
        )
    }

    func testCoreDefaultsMatchTheSotGeneratedExpectedSnapshot() throws {
        let url = try Self.expectedDefaultsURL()
        let data = try XCTUnwrap(
            try? Data(contentsOf: url),
            "could not read expected-defaults fixture at \(url.path) - "
                + "run scripts/defaults_generator/generate.py"
        )
        // SDC-32173 F2: the enrolled-module set is read from the generated snapshot
        // (not hardcoded here) so ENROLLED_MODULES and this test can never silently
        // diverge - if "core" is ever dropped from enrollment.py without updating/
        // removing this test, this fails loudly instead of quietly asserting nothing.
        let enrolledModules = try DefaultsDriftComparator.loadEnrolledModules(data: data)
        XCTAssertTrue(
            enrolledModules.contains("core"),
            "'core' is missing from the snapshot's enrolledModules \(enrolledModules) - "
                + "see scripts/defaults_generator/enrollment.py. This test asserts Core "
                + "defaults; if Core is no longer enrolled, this test must be updated too."
        )

        // SDC-33331: runtime subtrees the SoT knowingly does not model (declared in the
        // SoT via a group-level runtimeOnlyPrefix, stamped into the snapshot by the
        // generator). Read from the snapshot, never hardcoded here - that is exactly what
        // distinguishes this from the outOfScope set SDC-32173 review F1 removed.
        let runtimeOnlyPrefixes = try DefaultsDriftComparator.loadRuntimeOnlyPrefixes(data: data)

        let expected = try DefaultsDriftComparator.loadExpected(data: data)

        let dump = CoreWideDefaults.shared.toEncodable()
        let actual = DefaultsDriftComparator.flatten(
            dump: dump,
            modulePrefix: "Core",
            expectedPaths: Set(expected.keys)
        )

        let failures = DefaultsDriftComparator.compare(
            actual: actual,
            expected: expected,
            scopePrefixes: ["Core"],
            runtimeOnlyPrefixes: runtimeOnlyPrefixes
        )

        XCTAssertTrue(
            failures.isEmpty,
            "Core defaults drifted from the SoT:\n" + failures.joined(separator: "\n")
        )
    }
}
