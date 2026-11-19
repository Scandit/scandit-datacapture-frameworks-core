/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

public protocol FrameworkModule {
    func didStart()
    func didStop()
    func createCommand(_ method: FrameworksMethodCall) -> BaseCommand?
    func getDefaults() -> [String: Any?]
}
