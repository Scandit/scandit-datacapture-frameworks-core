/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

// Mirrors REDACTED_ARG_KEYS / REDACTED_ARG_METHODS in the TypeScript ScanditLogger; a jest test keeps them equal.
enum LogRedaction {
    static let maxArgChars = 8192
    private static let redacted = "[redacted]"

    static let redactedArgKeys: [String] = [
        "frameData",
        "viewBytes",
        "licenseKey",
        "deviceName",
        "externalId",
        "deviceOS",
        "deviceModelName",
        "deviceId",
        "barcodeResult",
        "mrzResult",
        "vizResult",
        "mobileDocumentResult",
        "mobileDocumentOcrResult",
        "verificationResult",
        "nfcResult",
        "imageInfo",
        "firstName",
        "lastName",
        "fullName",
        "sex",
        "dateOfBirth",
        "nationality",
        "nationalityISO",
        "address",
        "documentNumber",
        "documentAdditionalNumber",
        "passportNumber",
        "visaNumber",
        "dateOfExpiry",
        "dateOfIssue",
        "age",
        "frontReviewImage",
    ]

    static let redactedArgMethods: [String] = [
        "parseString",
        "parseRawData",
        "writeLogs",
        "appendLogs",
        "clearLogs",
    ]

    private static let redactedKeySet = Set(redactedArgKeys)

    static func redactFields(message: String, fields: [String: Any?]?) -> [String: Any?]? {
        guard var out = fields, out.keys.contains("args") else { return fields }
        let args: Any? = out["args"] ?? nil
        let result: Any? = isRedactedArgMethod(message) ? redactEveryValue(args) : args.map(redactValue)
        out["args"] = .some(result)
        return out
    }

    private static func isRedactedArgMethod(_ message: String) -> Bool {
        let method = message.split(separator: ".", omittingEmptySubsequences: false).last.map(String.init) ?? message
        let bare = String(method.drop(while: { $0 == "$" }))
        return redactedArgMethods.contains(bare)
    }

    private static func redactEveryValue(_ args: Any?) -> Any {
        if let dict = args as? [String: Any?] { return dict.mapValues { _ in redacted } }
        if let array = args as? [Any?] { return array.map { _ in redacted } }
        return redacted
    }

    private static func redactValue(_ value: Any) -> Any {
        if value is NSNull { return value }
        if let data = value as? Data { return "[omitted: \(data.count) bytes]" }
        if let string = value as? String { return redactString(string) }
        if let dict = value as? [String: Any?] { return redactDictionary(dict) }
        if let array = value as? [Any?] { return array.map { $0.map(redactValue) ?? NSNull() } }
        return value
    }

    private static func redactDictionary(_ dict: [String: Any?]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (key, value) in dict {
            out[key] = redactedKeySet.contains(key) ? redacted : (value.map(redactValue) ?? NSNull())
        }
        return out
    }

    private static func redactString(_ value: String) -> String {
        let length = value.utf16.count
        if length > maxArgChars { return "[omitted: \(length) chars]" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "{" || first == "[" else { return value }
        guard
            let parsed = try? JSONSerialization.jsonObject(with: Data(trimmed.utf8)),
            let data = try? JSONSerialization.data(withJSONObject: redactValue(parsed)),
            let text = String(data: data, encoding: .utf8)
        else { return value }
        return text
    }
}
