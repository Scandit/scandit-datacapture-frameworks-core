/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

// This class should be used only by the old modes that don't have a specific view.
open class BasicFrameworkModule<T>: NSObject, FrameworkModule {

    private var postModeCreationActions: [Int: [() -> Void]] = [:]
    private var modesCache: [Int: T] = [:]
    private var createdModes: [Int] = []

    // MARK: - FrameworkModule

    open func didStart() {
        // Implementation to be provided by subclasses
    }

    open func didStop() {
        // Implementation to be provided by subclasses
    }

    // MARK: - Mode Cache Management

    public func addModeToCache(modeId: Int, mode: T) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        modesCache[modeId] = mode
        createdModes.append(modeId)
    }

    public func getModeFromCache(_ modeId: Int) -> T? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        return modesCache[modeId]
    }

    public func getAllModesInCache() -> [T] {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        return Array(modesCache.values)
    }

     public func getModeFromCacheByParent(_ parentId: Int) -> FrameworksBaseMode? {
         objc_sync_enter(self)
         defer { objc_sync_exit(self) }
         
         return getAllModesInCache().compactMap{ $0 as? FrameworksBaseMode }.first { mode in
            mode.parentId == parentId
        }
    }

    public func removeModeFromCache(_ modeId: Int) -> T? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if let index = createdModes.firstIndex(of: modeId) {
            createdModes.remove(at: index)
        }
        return modesCache.removeValue(forKey: modeId)
    }

    public func getTopmostMode() -> T? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard let lastModeId = createdModes.last else {
            return nil
        }
        return modesCache[lastModeId]
    }

    // MARK: - Post Mode Creation Actions

    public func addPostModeCreationAction(_ modeId: Int, action: @escaping () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if postModeCreationActions[modeId] == nil {
            postModeCreationActions[modeId] = []
        }
        postModeCreationActions[modeId]?.append(action)
    }

    public func addPostModeCreationActionByParent(_ parentId: Int, action: @escaping () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if postModeCreationActions[parentId] == nil {
            postModeCreationActions[parentId] = []
        }
        postModeCreationActions[parentId]?.append(action)
    }

    public func removeAllModesFromCache() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        modesCache.removeAll()
        createdModes.removeAll()
    }

    public func getPostModeCreationActions(_ modeId: Int) -> [() -> Void] {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        var actions: [() -> Void] = []

        if let modeActions = postModeCreationActions[modeId] {
            actions.append(contentsOf: modeActions)
            postModeCreationActions[modeId] = []
        }

        return actions
    }

    public func getPostModeCreationActionsByParent(_ parentId: Int) -> [() -> Void] {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        var actions: [() -> Void] = []

        if let modeActions = postModeCreationActions[parentId] {
            actions.append(contentsOf: modeActions)
            postModeCreationActions[parentId] = []
        }

        return actions
    }

    public func clearPostModeCreationActions(_ modeId: Int?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if let modeId = modeId {
            postModeCreationActions.removeValue(forKey: modeId)
        } else {
            postModeCreationActions.removeAll()
        }
    }
}
