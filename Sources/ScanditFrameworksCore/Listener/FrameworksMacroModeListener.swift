/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class FrameworksMacroModeListener: NSObject {
    private let eventEmitter: Emitter
    private let macroModeChangedEvent = Event(.macroModeChanged)

    public init(eventEmitter: Emitter) {
        self.eventEmitter = eventEmitter
    }
}

extension FrameworksMacroModeListener: MacroModeListener {
    public func didChange(_ macroMode: MacroMode) {
        guard eventEmitter.hasListener(for: macroModeChangedEvent) else { return }
        macroModeChangedEvent.emit(on: eventEmitter, payload: ["macroMode": macroMode.jsonString])
    }
}
