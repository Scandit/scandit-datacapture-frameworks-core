/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import XCTest

@testable import ScanditFrameworksCore

final class ScanditLoggerRedactionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ScanditLoggerTestSupport.resetLogger()
        ScanditLogger.shared.setLevel(.trace)
    }

    override func tearDown() {
        ScanditLoggerTestSupport.resetLogger()
        super.tearDown()
    }

    private func emitWithArgs(_ message: String, _ args: Any?) -> [String: Any?]? {
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: message,
            fields: ["modeId": 3, "args": args]
        )
        return ScanditLogger.shared.getRecentLogs().first?.fields
    }

    func testARedactedKeyAnywhereInTheArgsIsReplaced() {
        let fields = emitWithArgs(
            "updateContext",
            ["licenseKey": "secret", "nested": [["firstName": "Ada", "ok": 1]]] as [String: Any?]
        )
        let args = fields?["args"] as? [String: Any?]
        XCTAssertEqual(args?["licenseKey"] as? String, "[redacted]")
        let nested = (args?["nested"] as? [Any?])?.first as? [String: Any?]
        XCTAssertEqual(nested?["firstName"] as? String, "[redacted]")
        XCTAssertEqual(nested?["ok"] as? Int, 1)
    }

    func testFieldsOtherThanArgsAreLeftAlone() {
        let fields = emitWithArgs("updateContext", ["licenseKey": "secret"] as [String: Any?])
        XCTAssertEqual(fields?["modeId"] as? Int, 3)
    }

    func testAJSONStringArgIsParsedAndItsRedactedKeysReplaced() {
        let fields = emitWithArgs("updateContext", ["settings": #"{"fullName":"Ada L","keep":"x"}"#] as [String: Any?])
        let args = fields?["args"] as? [String: Any?]
        let text = args?["settings"] as? String ?? ""
        let settings = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any]
        XCTAssertEqual(settings?["fullName"] as? String, "[redacted]")
        XCTAssertEqual(settings?["keep"] as? String, "x")
    }

    func testAStringLongerThanTheCapIsOmitted() {
        let fields = emitWithArgs("updateContext", ["blob": String(repeating: "a", count: 8193)] as [String: Any?])
        let args = fields?["args"] as? [String: Any?]
        XCTAssertEqual(args?["blob"] as? String, "[omitted: 8193 chars]")
    }

    func testAStringAtTheCapIsKept() {
        let text = String(repeating: "a", count: 8192)
        let fields = emitWithArgs("updateContext", ["blob": text] as [String: Any?])
        let args = fields?["args"] as? [String: Any?]
        XCTAssertEqual(args?["blob"] as? String, text)
    }

    func testEveryValueIsRedactedForARedactedMethod() {
        let fields = emitWithArgs("parseString", ["data": "harmless", "n": 2] as [String: Any?])
        let args = fields?["args"] as? [String: Any?]
        XCTAssertEqual(args?["data"] as? String, "[redacted]")
        XCTAssertEqual(args?["n"] as? String, "[redacted]")
    }

    func testAppendLogsArgsAreRedactedWholesale() {
        let fields = emitWithArgs("appendLogs", ["lines": "{}"] as [String: Any?])
        let args = fields?["args"] as? [String: Any?]
        XCTAssertEqual(args?["lines"] as? String, "[redacted]")
    }

    func testAMethodNameKeepsMatchingAfterASourcePrefixAndDollarSigns() {
        let fields = emitWithArgs("core.$writeLogs", ["header": "h"] as [String: Any?])
        let args = fields?["args"] as? [String: Any?]
        XCTAssertEqual(args?["header"] as? String, "[redacted]")
    }

    func testRecordsWithoutArgsPassThrough() {
        ScanditLogger.shared.emit(
            level: .debug,
            category: .bridge,
            source: "src",
            message: "m",
            fields: ["modeId": 1]
        )
        XCTAssertEqual(ScanditLogger.shared.getRecentLogs().first?.fields?["modeId"] as? Int, 1)
    }

    func testAnErrorStackIsDropped() {
        ScanditLogger.shared.emit(
            level: .error,
            category: .bridge,
            source: "src",
            message: "m",
            error: LogRecordError(name: "E", message: "boom", stack: "at secret.Path")
        )
        let error = ScanditLogger.shared.getRecentLogs().first?.error
        XCTAssertEqual(error?.message, "boom")
        XCTAssertNil(error?.stack)
    }
}
