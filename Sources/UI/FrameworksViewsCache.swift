/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class FrameworksViewsCache<T: FrameworksBaseView> {
    private var views: ConcurrentDictionary<Int, T> = ConcurrentDictionary()
    private var createdViews: [Int] = []
    
    public init() {
        
    }

    public func addView(view: T) {
        views.setValue(view, for: view.viewId)
        createdViews.append(view.viewId)
    }

    public func getView(viewId: Int) -> T? {
        return views.getValue(for: viewId)
    }

    public func getTopMost() -> T? {
        if let lastViewId = createdViews.last {
            return views.getValue(for: lastViewId)
        }
        return nil
    }

    public func remove(viewId: Int) -> T? {
        if let index = createdViews.firstIndex(of: viewId) {
            createdViews.remove(at: index)
        }
        return views.removeValue(for: viewId)
    }
    
    public func disposeAll() {
        views.getAllValues().forEach {
            $0.value.dispose()
        }
        views.removeAllValues()
        createdViews.removeAll()
    }
}
