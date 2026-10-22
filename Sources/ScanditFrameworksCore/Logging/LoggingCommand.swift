/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Decorating wrapper that emits a `Bridge`-category `LogRecord` for every
/// `BaseCommand.execute(result:)` invocation. Captures `modeId`/`viewId`/
/// `parentId` from the method arguments when present, plus the full inner
/// args, and propagates them so consumers can see exactly which
/// mode/view/parent the method targets.
///
/// Applied centrally in `CoreModule.execute(_:result:module:)` — no
/// per-command source edits are required.
public final class LoggingCommand: BaseCommand {
    private static let dispatcherKeys: Set<String> = ["moduleName", "methodName", "isEventRegistration"]
    private static let idKeys: Set<String> = ["modeId", "viewId", "parentId"]
    // Records sit in the ring buffer and ship in batches: frames, view bytes and
    // the license key must never be stored, and big strings blow the heap.
    private static let redactedKeys: Set<String> = ["frameData", "viewBytes", "licenseKey"]
    private static let redacted = "[redacted]"
    static let maxArgChars = 8192

    private let delegate: BaseCommand
    private let source: String
    private let method: FrameworksMethodCall

    public init(delegate: BaseCommand, source: String, method: FrameworksMethodCall) {
        self.delegate = delegate
        self.source = source
        self.method = method
    }

    public func execute(result: FrameworksResult) {
        let start = Int64(Date().timeIntervalSince1970 * 1000)
        let fields = extractFields()
        let methodName = method.method
        let src = source

        let forwarding = ForwardingResult(
            wrapped: result,
            onSuccess: { _ in
                ScanditLogger.shared.emit(
                    level: .debug,
                    category: .bridge,
                    source: src,
                    message: methodName,
                    fields: fields,
                    durationMs: Int64(Date().timeIntervalSince1970 * 1000) - start
                )
            },
            onKeepCallback: { _ in
                ScanditLogger.shared.emit(
                    level: .debug,
                    category: .listener,
                    source: src,
                    message: methodName,
                    fields: fields,
                    durationMs: Int64(Date().timeIntervalSince1970 * 1000) - start
                )
            },
            onReject: { code, message, details in
                ScanditLogger.shared.emit(
                    level: .error,
                    category: .bridge,
                    source: src,
                    message: methodName,
                    fields: fields,
                    durationMs: Int64(Date().timeIntervalSince1970 * 1000) - start,
                    error: LogRecordError(
                        name: code,
                        message: message ?? "",
                        stack: details.map { "\($0)" }
                    )
                )
            }
        )

        delegate.execute(result: forwarding)
    }

    private func extractFields() -> [String: Any?]? {
        let args = method.arguments()
        var out: [String: Any?] = [:]
        if let v = args["modeId"] as? Int {
            out["modeId"] = v
        } else if let n = args["modeId"] as? NSNumber {
            out["modeId"] = n.intValue
        }
        if let v = args["viewId"] as? Int {
            out["viewId"] = v
        } else if let n = args["viewId"] as? NSNumber {
            out["viewId"] = n.intValue
        }
        if let v = args["parentId"] as? Int {
            out["parentId"] = v
        } else if let n = args["parentId"] as? NSNumber {
            out["parentId"] = n.intValue
        }

        var inner: [String: Any?] = [:]
        for (key, value) in args {
            if Self.dispatcherKeys.contains(key) || Self.idKeys.contains(key) { continue }
            inner[key] = Self.sanitizeArg(key: key, value: value)
        }
        if !inner.isEmpty { out["args"] = inner }
        return out.isEmpty ? nil : out
    }

    static func sanitizeArg(key: String, value: Any) -> Any {
        if redactedKeys.contains(key) { return redacted }
        if let data = value as? Data { return "[omitted: \(data.count) bytes]" }
        guard let string = value as? String else { return value }
        let length = string.utf16.count
        if length > maxArgChars { return "[omitted: \(length) chars]" }
        guard string.contains("licenseKey") else { return string }
        return string.replacingOccurrences(
            of: #""licenseKey"\s*:\s*"[^"]*""#,
            with: "\"licenseKey\":\"\(redacted)\"",
            options: .regularExpression
        )
    }

    public static func wrap(
        _ delegate: BaseCommand,
        source: String,
        method: FrameworksMethodCall
    ) -> BaseCommand {
        if delegate is LoggingCommand { return delegate }
        return LoggingCommand(delegate: delegate, source: source, method: method)
    }
}

/// Internal forwarder — delegates every `FrameworksResult` method to the
/// underlying result and runs a callback for the three "terminal" methods we
/// care about logging (`success`, `successAndKeepCallback`, `reject`).
private final class ForwardingResult: FrameworksResult {
    private let wrapped: FrameworksResult
    private let onSuccess: (Any?) -> Void
    private let onKeepCallback: (Any?) -> Void
    private let onReject: (String, String?, Any?) -> Void

    init(
        wrapped: FrameworksResult,
        onSuccess: @escaping (Any?) -> Void,
        onKeepCallback: @escaping (Any?) -> Void,
        onReject: @escaping (String, String?, Any?) -> Void
    ) {
        self.wrapped = wrapped
        self.onSuccess = onSuccess
        self.onKeepCallback = onKeepCallback
        self.onReject = onReject
    }

    func success(result: Any?) {
        onSuccess(result)
        wrapped.success(result: result)
    }

    func successAndKeepCallback(result: Any?) {
        onKeepCallback(result)
        wrapped.successAndKeepCallback(result: result)
    }

    func reject(code: String, message: String?, details: Any?) {
        onReject(code, message, details)
        wrapped.reject(code: code, message: message, details: details)
    }

    func reject(error: Error) {
        onReject((error as NSError).domain, error.localizedDescription, nil)
        wrapped.reject(error: error)
    }

    func registerCallbackForEvents(_ eventNames: [String]) {
        wrapped.registerCallbackForEvents(eventNames)
    }
    func unregisterCallbackForEvents(_ eventNames: [String]) {
        wrapped.unregisterCallbackForEvents(eventNames)
    }
    func registerModeSpecificCallback(_ modeId: Int, eventNames: [String]) {
        wrapped.registerModeSpecificCallback(modeId, eventNames: eventNames)
    }
    func unregisterModeSpecificCallback(_ modeId: Int, eventNames: [String]) {
        wrapped.unregisterModeSpecificCallback(modeId, eventNames: eventNames)
    }
    func registerViewSpecificCallback(_ viewId: Int, eventNames: [String]) {
        wrapped.registerViewSpecificCallback(viewId, eventNames: eventNames)
    }
    func unregisterViewSpecificCallback(_ viewId: Int, eventNames: [String]) {
        wrapped.unregisterViewSpecificCallback(viewId, eventNames: eventNames)
    }
}
