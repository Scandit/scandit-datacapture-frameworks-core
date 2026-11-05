/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class RollingLogFileTests: XCTestCase {
    private var root: URL!
    private var logDirectory: URL { root.appendingPathComponent("Scandit/Logs") }

    override func setUp() {
        super.setUp()
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    private func read(_ name: String) -> String? {
        try? String(contentsOf: logDirectory.appendingPathComponent(name), encoding: .utf8)
    }

    func testReadAllOnAFreshDirectoryIsEmpty() {
        XCTAssertEqual(RollingLogFile(directory: logDirectory).readAll(), "")
    }

    func testAppendWritesLinesToTheCurrentFileAndReadAllReturnsThem() {
        let sut = RollingLogFile(directory: logDirectory)
        sut.append("one\ntwo\n")
        XCTAssertEqual(sut.readAll(), "one\ntwo\n")
        XCTAssertEqual(read("scandit-debug.log"), "one\ntwo\n")
    }

    func testAppendTerminatesALastLineThatHasNoNewline() {
        let sut = RollingLogFile(directory: logDirectory)
        sut.append("one")
        sut.append("two")
        XCTAssertEqual(sut.readAll(), "one\ntwo\n")
    }

    func testAnAppendThatWouldPassTheCapRotatesTheCurrentFileToThePreviousOne() {
        let sut = RollingLogFile(directory: logDirectory, maxBytes: 20)
        sut.append("aaaaaaaaaa\n")
        sut.append("bbbbbbbbbb\n")
        XCTAssertEqual(read("scandit-debug.1.log"), "aaaaaaaaaa\n")
        XCTAssertEqual(read("scandit-debug.log"), "bbbbbbbbbb\n")
    }

    func testAnAppendThatFitsTheCapExactlyDoesNotRotate() {
        let sut = RollingLogFile(directory: logDirectory, maxBytes: 22)
        sut.append("aaaaaaaaaa\n")
        sut.append("bbbbbbbbbb\n")
        XCTAssertNil(read("scandit-debug.1.log"))
    }

    func testReadAllReturnsThePreviousFileBeforeTheCurrentOne() {
        let sut = RollingLogFile(directory: logDirectory, maxBytes: 20)
        sut.append("aaaaaaaaaa\n")
        sut.append("bbbbbbbbbb\n")
        XCTAssertEqual(sut.readAll(), "aaaaaaaaaa\nbbbbbbbbbb\n")
    }

    func testASecondRotationDropsTheOldestFile() {
        let sut = RollingLogFile(directory: logDirectory, maxBytes: 20)
        sut.append("aaaaaaaaaa\n")
        sut.append("bbbbbbbbbb\n")
        sut.append("cccccccccc\n")
        XCTAssertEqual(sut.readAll(), "bbbbbbbbbb\ncccccccccc\n")
    }

    func testASingleAppendLargerThanTheCapIsStillWrittenWhole() {
        let sut = RollingLogFile(directory: logDirectory, maxBytes: 5)
        sut.append("far-too-long-for-the-cap\n")
        XCTAssertEqual(sut.readAll(), "far-too-long-for-the-cap\n")
    }

    func testAReopenedFileAppendsAfterWhatIsAlreadyThere() {
        RollingLogFile(directory: logDirectory).append("before\n")
        let reopened = RollingLogFile(directory: logDirectory)
        reopened.append("after\n")
        XCTAssertEqual(reopened.readAll(), "before\nafter\n")
    }

    func testDeleteRemovesBothFilesAndTheNextAppendStartsClean() {
        let sut = RollingLogFile(directory: logDirectory, maxBytes: 20)
        sut.append("aaaaaaaaaa\n")
        sut.append("bbbbbbbbbb\n")
        sut.delete()
        XCTAssertEqual(sut.readAll(), "")
        XCTAssertNil(read("scandit-debug.log"))
        XCTAssertNil(read("scandit-debug.1.log"))
        sut.append("fresh\n")
        XCTAssertEqual(sut.readAll(), "fresh\n")
    }

    func testDeleteOnADirectoryThatDoesNotExistIsHarmless() {
        RollingLogFile(directory: logDirectory).delete()
        XCTAssertEqual(RollingLogFile(directory: logDirectory).readAll(), "")
    }

    func testAFailedAppendReturnsSilentlyAndTheNextAppendCountsTheSizeFromDisk() throws {
        let sut = RollingLogFile(directory: logDirectory, maxBytes: 10)
        let blocker = logDirectory
        try FileManager.default.createDirectory(
            at: blocker.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        XCTAssertTrue(FileManager.default.createFile(atPath: blocker.path, contents: nil))
        sut.append("abc\n")
        try FileManager.default.removeItem(at: blocker)
        sut.append("abc\n")
        sut.append("defgh\n")
        XCTAssertEqual(sut.readAll(), "abc\ndefgh\n")
        XCTAssertNil(read("scandit-debug.1.log"))
    }

    func testAppendingAnEmptyStringCreatesNoFile() {
        RollingLogFile(directory: logDirectory).append("")
        XCTAssertNil(read("scandit-debug.log"))
    }

    func testTheLogDirectoryIsExcludedFromBackup() throws {
        RollingLogFile(directory: logDirectory).append("line\n")
        let values = try logDirectory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }
}
