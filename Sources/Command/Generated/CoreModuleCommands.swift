/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

// THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
// Generator: scripts/bridge_generator/generate.py
// Schema: scripts/bridge_generator/schemas/core.json

import Foundation

/// Generated CoreModule command implementations.
/// Each command extracts parameters in its initializer and executes via CoreModule.

/// Gets the camera state for a given position
public class GetCameraStateCommand: CoreModuleCommand {
    private let module: CoreModule
    private let cameraPosition: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.cameraPosition = method.argument(key: "cameraPosition") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !cameraPosition.isEmpty else {
            result.reject(
                code: "MISSING_PARAMETER",
                message: "Required parameter 'cameraPosition' is missing",
                details: nil
            )
            return
        }
        module.getCameraState(
            cameraPosition: cameraPosition,
            result: result
        )
    }
}
/// Switches the camera to the desired state
public class SwitchCameraToDesiredStateCommand: CoreModuleCommand {
    private let module: CoreModule
    private let stateJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.stateJson = method.argument(key: "stateJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !stateJson.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'stateJson' is missing", details: nil)
            return
        }
        module.switchCameraToDesiredState(
            stateJson: stateJson,
            result: result
        )
    }
}
/// Checks if torch is available for the given camera position
public class IsTorchAvailableCommand: CoreModuleCommand {
    private let module: CoreModule
    private let cameraPosition: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.cameraPosition = method.argument(key: "cameraPosition") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !cameraPosition.isEmpty else {
            result.reject(
                code: "MISSING_PARAMETER",
                message: "Required parameter 'cameraPosition' is missing",
                details: nil
            )
            return
        }
        module.isTorchAvailable(
            cameraPosition: cameraPosition,
            result: result
        )
    }
}
/// Registers a persistent listener for frame source state change events
public class RegisterFrameSourceListenerCommand: CoreModuleCommand {
    private let module: CoreModule
    public init(module: CoreModule) {
        self.module = module
    }

    public func execute(result: FrameworksResult) {
        // Register/unregister event callbacks
        result.registerCallbackForEvents([
            "FrameSourceListener.onStateChanged",
            "TorchListener.onTorchStateChanged",
        ])
        module.registerFrameSourceListener(
            result: result
        )
    }
}
/// Unregisters the frame source event listener
public class UnregisterFrameSourceListenerCommand: CoreModuleCommand {
    private let module: CoreModule
    public init(module: CoreModule) {
        self.module = module
    }

    public func execute(result: FrameworksResult) {
        // Register/unregister event callbacks
        result.unregisterCallbackForEvents([
            "FrameSourceListener.onStateChanged",
            "TorchListener.onTorchStateChanged",
        ])
        module.unregisterFrameSourceListener(
            result: result
        )
    }
}
/// Gets the last frame data by frame ID as JSON
public class GetLastFrameAsJsonCommand: CoreModuleCommand {
    private let module: CoreModule
    private let frameId: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.frameId = method.argument(key: "frameId") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !frameId.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'frameId' is missing", details: nil)
            return
        }
        module.getLastFrameAsJson(
            frameId: frameId,
            result: result
        )
    }
}
/// Gets the last frame data by frame ID as JSON, or null if not found
public class GetLastFrameOrNullAsJsonCommand: CoreModuleCommand {
    private let module: CoreModule
    private let frameId: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.frameId = method.argument(key: "frameId") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !frameId.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'frameId' is missing", details: nil)
            return
        }
        module.getLastFrameOrNullAsJson(
            frameId: frameId,
            result: result
        )
    }
}
/// Gets the last frame data by frame ID as a map, or null if not found
public class GetLastFrameOrNullAsMapCommand: CoreModuleCommand {
    private let module: CoreModule
    private let frameId: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.frameId = method.argument(key: "frameId") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !frameId.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'frameId' is missing", details: nil)
            return
        }
        module.getLastFrameOrNullAsMap(
            frameId: frameId,
            result: result
        )
    }
}
/// Creates a DataCaptureContext from JSON
public class CreateContextFromJsonCommand: CoreModuleCommand {
    private let module: CoreModule
    private let contextJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.contextJson = method.argument(key: "contextJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !contextJson.isEmpty else {
            result.reject(
                code: "MISSING_PARAMETER",
                message: "Required parameter 'contextJson' is missing",
                details: nil
            )
            return
        }
        module.createContextFromJson(
            contextJson: contextJson,
            result: result
        )
    }
}
/// Updates a DataCaptureContext from JSON
public class UpdateContextFromJsonCommand: CoreModuleCommand {
    private let module: CoreModule
    private let contextJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.contextJson = method.argument(key: "contextJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !contextJson.isEmpty else {
            result.reject(
                code: "MISSING_PARAMETER",
                message: "Required parameter 'contextJson' is missing",
                details: nil
            )
            return
        }
        module.updateContextFromJson(
            contextJson: contextJson,
            result: result
        )
    }
}
/// Subscribes to context events with persistent listener
public class SubscribeContextListenerCommand: CoreModuleCommand {
    private let module: CoreModule
    public init(module: CoreModule) {
        self.module = module
    }

    public func execute(result: FrameworksResult) {
        // Register/unregister event callbacks
        result.registerCallbackForEvents([
            "DataCaptureContextListener.onObservationStarted",
            "DataCaptureContextListener.onStatusChanged",
        ])
        module.subscribeContextListener(
            result: result
        )
    }
}
/// Unsubscribes from context events
public class UnsubscribeContextListenerCommand: CoreModuleCommand {
    private let module: CoreModule
    public init(module: CoreModule) {
        self.module = module
    }

    public func execute(result: FrameworksResult) {
        // Register/unregister event callbacks
        result.unregisterCallbackForEvents([
            "DataCaptureContextListener.onObservationStarted",
            "DataCaptureContextListener.onStatusChanged",
        ])
        module.unsubscribeContextListener(
            result: result
        )
    }
}
/// Adds a mode to the DataCaptureContext
public class AddModeToContextCommand: CoreModuleCommand {
    private let module: CoreModule
    private let modeJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.modeJson = method.argument(key: "modeJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !modeJson.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'modeJson' is missing", details: nil)
            return
        }
        module.addModeToContext(
            modeJson: modeJson,
            result: result
        )
    }
}
/// Removes a mode from the DataCaptureContext
public class RemoveModeFromContextCommand: CoreModuleCommand {
    private let module: CoreModule
    private let modeJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.modeJson = method.argument(key: "modeJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !modeJson.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'modeJson' is missing", details: nil)
            return
        }
        module.removeModeFromContext(
            modeJson: modeJson,
            result: result
        )
    }
}
/// Removes all modes from the DataCaptureContext
public class RemoveAllModesCommand: CoreModuleCommand {
    private let module: CoreModule
    public init(module: CoreModule) {
        self.module = module
    }

    public func execute(result: FrameworksResult) {
        module.removeAllModes(
            result: result
        )
    }
}
/// Gets open source software license information
public class GetOpenSourceSoftwareLicenseInfoCommand: CoreModuleCommand {
    private let module: CoreModule
    public init(module: CoreModule) {
        self.module = module
    }

    public func execute(result: FrameworksResult) {
        module.getOpenSourceSoftwareLicenseInfo(
            result: result
        )
    }
}
/// Disposes the DataCaptureContext and releases resources
public class DisposeContextCommand: CoreModuleCommand {
    private let module: CoreModule
    public init(module: CoreModule) {
        self.module = module
    }

    public func execute(result: FrameworksResult) {
        module.disposeContext(
            result: result
        )
    }
}
/// Converts a point from frame coordinates to view coordinates
public class ViewPointForFramePointCommand: CoreModuleCommand {
    private let module: CoreModule
    private let viewId: Int
    private let pointJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.viewId = method.argument(key: "viewId") ?? Int()
        self.pointJson = method.argument(key: "pointJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !pointJson.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'pointJson' is missing", details: nil)
            return
        }
        module.viewPointForFramePoint(
            viewId: viewId,
            pointJson: pointJson,
            result: result
        )
    }
}
/// Converts a quadrilateral from frame coordinates to view coordinates
public class ViewQuadrilateralForFrameQuadrilateralCommand: CoreModuleCommand {
    private let module: CoreModule
    private let viewId: Int
    private let quadrilateralJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.viewId = method.argument(key: "viewId") ?? Int()
        self.quadrilateralJson = method.argument(key: "quadrilateralJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !quadrilateralJson.isEmpty else {
            result.reject(
                code: "MISSING_PARAMETER",
                message: "Required parameter 'quadrilateralJson' is missing",
                details: nil
            )
            return
        }
        module.viewQuadrilateralForFrameQuadrilateral(
            viewId: viewId,
            quadrilateralJson: quadrilateralJson,
            result: result
        )
    }
}
/// Registers persistent event listener for view events
public class RegisterListenerForViewEventsCommand: CoreModuleCommand {
    private let module: CoreModule
    private let viewId: Int
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.viewId = method.argument(key: "viewId") ?? Int()
    }

    public func execute(result: FrameworksResult) {
        // Register/unregister event callbacks
        result.registerCallbackForEvents([
            "DataCaptureViewListener.onSizeChanged"
        ])
        module.registerListenerForViewEvents(
            viewId: viewId,
            result: result
        )
    }
}
/// Unregisters the view event listener
public class UnregisterListenerForViewEventsCommand: CoreModuleCommand {
    private let module: CoreModule
    private let viewId: Int
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.viewId = method.argument(key: "viewId") ?? Int()
    }

    public func execute(result: FrameworksResult) {
        // Register/unregister event callbacks
        result.unregisterCallbackForEvents([
            "DataCaptureViewListener.onSizeChanged"
        ])
        module.unregisterListenerForViewEvents(
            viewId: viewId,
            result: result
        )
    }
}
/// Updates the DataCaptureView configuration
public class UpdateDataCaptureViewCommand: CoreModuleCommand {
    private let module: CoreModule
    private let viewJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.viewJson = method.argument(key: "viewJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !viewJson.isEmpty else {
            result.reject(code: "MISSING_PARAMETER", message: "Required parameter 'viewJson' is missing", details: nil)
            return
        }
        module.updateDataCaptureView(
            viewJson: viewJson,
            result: result
        )
    }
}
/// Emits haptic/audio feedback
public class EmitFeedbackCommand: CoreModuleCommand {
    private let module: CoreModule
    private let feedbackJson: String
    public init(module: CoreModule, _ method: FrameworksMethodCall) {
        self.module = module
        self.feedbackJson = method.argument(key: "feedbackJson") ?? ""
    }

    public func execute(result: FrameworksResult) {
        guard !feedbackJson.isEmpty else {
            result.reject(
                code: "MISSING_PARAMETER",
                message: "Required parameter 'feedbackJson' is missing",
                details: nil
            )
            return
        }
        module.emitFeedback(
            feedbackJson: feedbackJson,
            result: result
        )
    }
}
