/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation

public class ConcurrentDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]
    private let queue = DispatchQueue(
        label: "com.scandit.frameworks.ConcurrentDictionaryQueue",
        attributes: .concurrent
    )

    public init() {}

    public func setValue(_ value: Value, for key: Key) {
        queue.async(flags: .barrier) {
            self.dictionary[key] = value
        }
    }

    public func getValue(for key: Key) -> Value? {
        var result: Value?
        queue.sync {
            result = self.dictionary[key]
        }
        return result
    }

    public func removeValue(for key: Key) -> Value? {
        var result: Value?
        queue.sync(flags: .barrier) {
            result = self.dictionary.removeValue(forKey: key)
        }
        return result
    }

    public func getAllValues() -> [Key: Value] {
        var currentDictionary: [Key: Value] = [:]
        queue.sync {
            currentDictionary = self.dictionary
        }
        return currentDictionary
    }

    public func removeAllValues() {
        queue.async(flags: .barrier) {
            self.dictionary.removeAll()
        }
    }
}
