/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.scandit.datacapture"

    static let sdcFrameworks = OSLog(subsystem: subsystem, category: "sdc-frameworks")
}

public class Log {
    public static func error(_ message: StaticString) {
        log(message, type: .error)
    }

    public static func info(_ message: StaticString) {
        log(message, type: .info)
    }

    public static func info(_ message: String) {
        os_log("%@", log: OSLog.sdcFrameworks, type: .info, message)
    }

    public static func error(_ error: Error) {
        os_log("%@", log: OSLog.sdcFrameworks, type: .error, error.localizedDescription)
    }

    public static func error(_ message: String, error: Error) {
        os_log("%@", log: OSLog.sdcFrameworks, type: .error, "\(message) \(error.localizedDescription)")
    }

    private static func log(_ message: StaticString, type: OSLogType) {
        os_log(message, log: OSLog.sdcFrameworks, type: type)
    }
}
