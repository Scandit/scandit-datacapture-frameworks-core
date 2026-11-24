/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

final class RollingLogFile {
    static let currentName = "scandit-debug.log"
    static let previousName = "scandit-debug.1.log"
    static let defaultMaxBytes = 5 * 1024 * 1024

    let directory: URL
    private let maxBytes: Int
    private let lock = NSLock()
    private var directoryReady = false
    // Size of the current file; nil until read from disk, so a reopened directory keeps its bytes.
    private var currentSize: Int?

    init(directory: URL, maxBytes: Int = RollingLogFile.defaultMaxBytes) {
        self.directory = directory
        self.maxBytes = maxBytes
    }

    private var current: URL { directory.appendingPathComponent(Self.currentName) }
    private var previous: URL { directory.appendingPathComponent(Self.previousName) }

    /// Appends `text`, rotating first when it would push the current file past the cap.
    func append(_ text: String) {
        guard !text.isEmpty else { return }
        let data = Data((text.hasSuffix("\n") ? text : text + "\n").utf8)
        lock.lock()
        defer { lock.unlock() }
        if !directoryReady {
            prepareDirectory()
            directoryReady = true
        }
        var size = currentSize ?? fileSize(current)
        if size > 0, size + data.count > maxBytes {
            rotate()
            size = 0
        }
        if write(data) {
            currentSize = size + data.count
        } else {
            directoryReady = false
            currentSize = nil
        }
    }

    /// Both files' contents, oldest first.
    func readAll() -> String {
        lock.lock()
        defer { lock.unlock() }
        return [previous, current].compactMap { try? String(contentsOf: $0, encoding: .utf8) }.joined()
    }

    func delete() {
        lock.lock()
        defer { lock.unlock() }
        try? FileManager.default.removeItem(at: current)
        try? FileManager.default.removeItem(at: previous)
        directoryReady = false
        currentSize = nil
    }

    private func prepareDirectory() {
        let manager = FileManager.default
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    private func fileSize(_ url: URL) -> Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.intValue ?? 0
    }

    private func rotate() {
        try? FileManager.default.removeItem(at: previous)
        if (try? FileManager.default.moveItem(at: current, to: previous)) == nil {
            try? FileManager.default.removeItem(at: current)
        }
    }

    private func write(_ data: Data) -> Bool {
        if !FileManager.default.fileExists(atPath: current.path) {
            return FileManager.default.createFile(atPath: current.path, contents: data)
        }
        guard let handle = try? FileHandle(forWritingTo: current) else { return false }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        return (try? handle.write(contentsOf: data)) != nil
    }
}
