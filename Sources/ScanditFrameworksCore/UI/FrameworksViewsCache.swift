/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class FrameworksViewsCache<T: FrameworksBaseView> {
    private var views: ConcurrentDictionary<Int, T> = ConcurrentDictionary()
    private var createdViews: [Int] = []
    private let lock = NSLock()

    public init() {

    }

    public func addView(view: T) {
        views.setValue(view, for: view.viewId)
        lock.lock()
        createdViews.append(view.viewId)
        lock.unlock()
    }

    public func getView(viewId: Int) -> T? {
        views.getValue(for: viewId)
    }

    public func getTopMost() -> T? {
        lock.lock()
        let lastViewId = createdViews.last
        lock.unlock()
        if let lastViewId = lastViewId {
            return views.getValue(for: lastViewId)
        }
        return nil
    }

    public func remove(viewId: Int) -> T? {
        lock.lock()
        if let index = createdViews.firstIndex(of: viewId) {
            createdViews.remove(at: index)
        }
        lock.unlock()
        return views.removeValue(for: viewId)
    }

    public func disposeAll() {
        views.getAllValues().forEach {
            $0.value.dispose()
        }
        views.removeAllValues()
        lock.lock()
        createdViews.removeAll()
        lock.unlock()
    }
}
