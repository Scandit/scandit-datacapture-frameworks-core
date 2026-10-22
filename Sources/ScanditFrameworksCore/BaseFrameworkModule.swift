/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

open class BaseFrameworkModule: NSObject, FrameworkModule {

    private let postViewCreationActionsQueue = DispatchQueue(
        label: "com.scandit.postViewCreationActions"
    )
    private var postViewCreationActions: [() -> Void] = []
    private let viewCreationActionQueue = ViewCreationActionQueue()

    // MARK: - FrameworkModule

    open func didStart() {
        // Implementation to be provided by subclasses
    }

    open func didStop() {
        clearAllPostViewCreationActions()
    }

    open func createCommand(_ method: any FrameworksMethodCall) -> (any BaseCommand)? {
        nil
    }

    // MARK: - Post View Creation Actions

    public func addPostViewCreationAction(action: @escaping () -> Void) {
        postViewCreationActionsQueue.sync {
            postViewCreationActions.append(action)
        }
    }

    public func addPostSpecificViewCreationAction(viewId: Int, action: @escaping () -> Void) {
        viewCreationActionQueue.enqueue(viewId: viewId, action: action)
    }

    public func getPostSpecificViewCreationActions(viewId: Int) -> [() -> Void] {
        viewCreationActionQueue.drain(viewId: viewId)
    }

    public func clearPostViewCreationActions() {
        postViewCreationActionsQueue.sync {
            postViewCreationActions.removeAll()
        }
    }

    public func clearPostSpecificViewCreationActions(viewId: Int) {
        viewCreationActionQueue.clear(viewId: viewId)
    }

    public func clearAllPostViewCreationActions() {
        postViewCreationActionsQueue.sync {
            postViewCreationActions.removeAll()
        }
        viewCreationActionQueue.clearAll()
    }
}
