/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Merges native fields (platform/osVersion/appId) into the TS-built header and writes the
/// export to the caller-supplied path.
enum LogExportFile {
    enum ExportError: Error, Equatable, LocalizedError {
        case emptyPath
        case malformedHeader
        case notWritable(String)

        var errorDescription: String? {
            switch self {
            case .emptyPath:
                return "writeLogs: the destination path is empty"
            case .malformedHeader:
                return "writeLogs: malformed header JSON"
            case .notWritable(let path):
                return "writeLogs: cannot write to \(path). An app can only write inside its own "
                    + "container: pass a path under the app's Documents, Library or temporary "
                    + "directory, or a relative path, which is resolved against Documents."
            }
        }
    }

    /// Writes the export to `path`, creating missing parent directories. A relative `path` is
    /// resolved against `baseDirectory` — the app's documents directory — and an absolute one is
    /// used as given. The destination belongs to the caller: nothing else in it is touched.
    static func write(
        baseDirectory: URL,
        path: String,
        headerJson: String,
        body: String,
        extras: [String: String]
    ) throws -> URL {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExportError.emptyPath
        }
        guard
            let headerData = headerJson.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any]
        else {
            throw ExportError.malformedHeader
        }

        var header = parsed
        for (key, value) in extras { header[key] = value }
        let headerOut = try JSONSerialization.data(withJSONObject: header)
        guard let headerString = String(data: headerOut, encoding: .utf8) else {
            throw ExportError.malformedHeader
        }

        let fileURL = resolve(baseDirectory: baseDirectory, path: path)
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw ExportError.notWritable(fileURL.path)
        }

        let contents = headerString + "\n" + body + "\n"
        do {
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.notWritable(fileURL.path)
        }
        return fileURL
    }

    private static func resolve(baseDirectory: URL, path: String) -> URL {
        (path as NSString).isAbsolutePath
            ? URL(fileURLWithPath: path)
            : baseDirectory.appendingPathComponent(path)
    }
}
