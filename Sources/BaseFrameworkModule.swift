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
    private var postSpecificViewCreationActions: [Int: [() -> Void]] = [:]

    // MARK: - FrameworkModule

    open func didStart() {
        // Implementation to be provided by subclasses
    }

    open func didStop() {
        clearAllPostViewCreationActions()
    }

    open func getDefaults() -> [String: Any?] {
        // Implementation to be provided by subclasses
        [:]
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
        postViewCreationActionsQueue.sync {
            if postSpecificViewCreationActions[viewId] == nil {
                postSpecificViewCreationActions[viewId] = []
            }
            postSpecificViewCreationActions[viewId]?.append(action)
        }
    }

    public func getPostSpecificViewCreationActions(viewId: Int) -> [() -> Void] {
        postViewCreationActionsQueue.sync {
            guard let actions = postSpecificViewCreationActions[viewId] else {
                return []
            }
            let result = actions
            _ = postSpecificViewCreationActions.removeValue(forKey: viewId)
            return result
        }
    }

    public func clearPostViewCreationActions() {
        postViewCreationActionsQueue.sync {
            postViewCreationActions.removeAll()
        }
    }

    public func clearPostSpecificViewCreationActions(viewId: Int) {
        postViewCreationActionsQueue.sync {
            _ = postSpecificViewCreationActions.removeValue(forKey: viewId)
        }
    }

    public func clearAllPostViewCreationActions() {
        postViewCreationActionsQueue.sync {
            postViewCreationActions.removeAll()
            postSpecificViewCreationActions.removeAll()
        }
    }
}
