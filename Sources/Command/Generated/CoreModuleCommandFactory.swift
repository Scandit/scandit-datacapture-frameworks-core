/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

// THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
// Generator: scripts/bridge_generator/generate.py
// Schema: scripts/bridge_generator/schemas/core.json

import Foundation

/// Factory for creating CoreModule commands from method calls.
/// Maps method names to their corresponding command implementations.
public class CoreModuleCommandFactory {
    /// Creates a command from a FrameworksMethodCall.
    ///
    /// - Parameter module: The CoreModule instance to bind to the command
    /// - Parameter method: The method call containing method name and arguments
    /// - Returns: The corresponding command, or nil if method is not recognized
    public static func create(module: CoreModule, _ method: FrameworksMethodCall) -> CoreModuleCommand? {
        switch method.method {
        case "getCameraState":
            return GetCameraStateCommand(module: module, method)
        case "switchCameraToDesiredState":
            return SwitchCameraToDesiredStateCommand(module: module, method)
        case "isTorchAvailable":
            return IsTorchAvailableCommand(module: module, method)
        case "registerFrameSourceListener":
            return RegisterFrameSourceListenerCommand(module: module)
        case "unregisterFrameSourceListener":
            return UnregisterFrameSourceListenerCommand(module: module)
        case "getLastFrameAsJson":
            return GetLastFrameAsJsonCommand(module: module, method)
        case "getLastFrameOrNullAsJson":
            return GetLastFrameOrNullAsJsonCommand(module: module, method)
        case "getLastFrameOrNullAsMap":
            return GetLastFrameOrNullAsMapCommand(module: module, method)
        case "createContextFromJson":
            return CreateContextFromJsonCommand(module: module, method)
        case "updateContextFromJson":
            return UpdateContextFromJsonCommand(module: module, method)
        case "subscribeContextListener":
            return SubscribeContextListenerCommand(module: module)
        case "unsubscribeContextListener":
            return UnsubscribeContextListenerCommand(module: module)
        case "addModeToContext":
            return AddModeToContextCommand(module: module, method)
        case "removeModeFromContext":
            return RemoveModeFromContextCommand(module: module, method)
        case "removeAllModes":
            return RemoveAllModesCommand(module: module)
        case "getOpenSourceSoftwareLicenseInfo":
            return GetOpenSourceSoftwareLicenseInfoCommand(module: module)
        case "disposeContext":
            return DisposeContextCommand(module: module)
        case "viewPointForFramePoint":
            return ViewPointForFramePointCommand(module: module, method)
        case "viewQuadrilateralForFrameQuadrilateral":
            return ViewQuadrilateralForFrameQuadrilateralCommand(module: module, method)
        case "registerListenerForViewEvents":
            return RegisterListenerForViewEventsCommand(module: module, method)
        case "unregisterListenerForViewEvents":
            return UnregisterListenerForViewEventsCommand(module: module, method)
        case "updateDataCaptureView":
            return UpdateDataCaptureViewCommand(module: module, method)
        case "emitFeedback":
            return EmitFeedbackCommand(module: module, method)
        default:
            return nil
        }
    }
}
