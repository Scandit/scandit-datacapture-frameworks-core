/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class LogExportFileTests: XCTestCase {
    private var baseDirectory: URL!

    override func setUp() {
        super.setUp()
        baseDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseDirectory)
        super.tearDown()
    }

    func testWrittenFileFirstLineIsHeaderJsonWithExtrasMergedFollowedByBodyVerbatim() throws {
        let header = "{\"type\":\"scandit-debug-log\",\"recordCount\":2}"
        let body = "{\"message\":\"m1\"}\n{\"message\":\"m2\"}"
        let extras = ["platform": "ios", "osVersion": "17.0", "appId": "com.example.app"]

        let fileURL = try LogExportFile.write(
            baseDirectory: baseDirectory,
            path: "scandit-debug-log-test.jsonl",
            headerJson: header,
            body: body,
            extras: extras
        )

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = contents.components(separatedBy: "\n")
        let headerData = lines[0].data(using: .utf8)!
        let writtenHeader = try JSONSerialization.jsonObject(with: headerData) as! [String: Any]

        XCTAssertEqual(writtenHeader["type"] as? String, "scandit-debug-log")
        XCTAssertEqual(writtenHeader["recordCount"] as? Int, 2)
        XCTAssertEqual(writtenHeader["platform"] as? String, "ios")
        XCTAssertEqual(writtenHeader["osVersion"] as? String, "17.0")
        XCTAssertEqual(writtenHeader["appId"] as? String, "com.example.app")
        XCTAssertEqual(lines.dropFirst().dropLast().joined(separator: "\n"), body)
    }

    func testRelativePathIsResolvedAgainstTheAppDocumentsDirectory() throws {
        let fileURL = try LogExportFile.write(
            baseDirectory: baseDirectory,
            path: "logs/export.jsonl",
            headerJson: "{}",
            body: "body",
            extras: [:]
        )

        XCTAssertEqual(fileURL.path, baseDirectory.appendingPathComponent("logs/export.jsonl").path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testAbsolutePathIsUsedAsGiven() throws {
        let elsewhere = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: elsewhere) }
        let destination = elsewhere.appendingPathComponent("export.jsonl")

        let fileURL = try LogExportFile.write(
            baseDirectory: baseDirectory,
            path: destination.path,
            headerJson: "{}",
            body: "body",
            extras: [:]
        )

        XCTAssertEqual(fileURL.path, destination.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
    }

    func testNothingTheCallerDidNotAskForIsDeleted() throws {
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        let neighbour = baseDirectory.appendingPathComponent("someone-elses-file.txt")
        try "keep me".write(to: neighbour, atomically: true, encoding: .utf8)

        _ = try LogExportFile.write(
            baseDirectory: baseDirectory,
            path: "scandit-debug-log-new.jsonl",
            headerJson: "{}",
            body: "body",
            extras: [:]
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: neighbour.path))
    }

    func testAPathThatCannotBeWrittenThrowsNotWritableWithAnActionableMessage() throws {
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        // A regular file where a directory would have to be: the parent cannot be created.
        let blocker = baseDirectory.appendingPathComponent("not-a-directory")
        try "".write(to: blocker, atomically: true, encoding: .utf8)
        let destination = blocker.appendingPathComponent("export.jsonl")

        XCTAssertThrowsError(
            try LogExportFile.write(
                baseDirectory: baseDirectory,
                path: destination.path,
                headerJson: "{}",
                body: "body",
                extras: [:]
            )
        ) { error in
            XCTAssertEqual(error as? LogExportFile.ExportError, .notWritable(destination.path))
            XCTAssertTrue(error.localizedDescription.contains("its own container"))
        }
    }

    func testEmptyPathThrows() {
        XCTAssertThrowsError(
            try LogExportFile.write(
                baseDirectory: baseDirectory,
                path: "   ",
                headerJson: "{}",
                body: "body",
                extras: [:]
            )
        ) { error in
            XCTAssertEqual(error as? LogExportFile.ExportError, .emptyPath)
        }
    }

    func testMalformedHeaderJsonThrowsAndWritesNothing() {
        let fileName = "scandit-debug-log-bad.jsonl"

        XCTAssertThrowsError(
            try LogExportFile.write(
                baseDirectory: baseDirectory,
                path: fileName,
                headerJson: "{not valid json",
                body: "body",
                extras: [:]
            )
        ) { error in
            XCTAssertEqual(error as? LogExportFile.ExportError, .malformedHeader)
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: baseDirectory.appendingPathComponent(fileName).path))
    }
}
