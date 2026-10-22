/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Parks registration/listener-attachment actions requested for a `viewId` whose native
/// view hasn't been added to its module's view cache yet.
///
/// New-architecture view creation can race the JS registration call: `register*`/`add*Listener`
/// methods used to optional-chain into the cached view and, on a cache miss, silently no-op
/// while still reporting success — JS believed it registered, but no events ever fired
/// (SDC-32821).
///
/// This is the single shared implementation of per-view action parking: `BaseFrameworkModule`
/// holds one instance and delegates its `addPostSpecificViewCreationAction` /
/// `getPostSpecificViewCreationActions` / `clearPostSpecificViewCreationActions` /
/// `clearAllPostViewCreationActions` methods to it, and modules that don't derive from
/// `BaseFrameworkModule` (e.g. `BarcodeCountModule`, `BarcodeFindModule`, `BarcodePickModule`,
/// `SparkScanModule`) own an instance of this type directly, without repeating the storage +
/// locking in every module.
///
/// Usage: a `register*` method enqueues an action on a cache miss (and still resolves the
/// bridge callback immediately, matching the pre-existing `successAndKeepCallback` semantics
/// so a never-created view doesn't leak the callback); the view-creation method drains and
/// runs the parked actions **after** adding the new view to the cache, so each action's own
/// cache lookup succeeds.
public final class ViewCreationActionQueue {
    private let lock = NSLock()
    private var actionsByViewId: [Int: [() -> Void]] = [:]

    public init() {}

    /// Parks `action` for `viewId`. Call when a registration races view creation.
    public func enqueue(viewId: Int, action: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        actionsByViewId[viewId, default: []].append(action)
    }

    /// Removes and returns every action parked for `viewId`, in enqueue order.
    /// Call only after the view has been added to the cache — the actions look the view up
    /// again by id, so draining before the cache insert would just re-park them forever.
    public func drain(viewId: Int) -> [() -> Void] {
        lock.lock()
        defer { lock.unlock() }
        return actionsByViewId.removeValue(forKey: viewId) ?? []
    }

    /// Drops any parked actions for `viewId` without running them (e.g. the view was removed
    /// before it was ever (re)created).
    public func clear(viewId: Int) {
        lock.lock()
        defer { lock.unlock() }
        actionsByViewId.removeValue(forKey: viewId)
    }

    /// Drops every parked action across all views (module teardown).
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        actionsByViewId.removeAll()
    }
}
