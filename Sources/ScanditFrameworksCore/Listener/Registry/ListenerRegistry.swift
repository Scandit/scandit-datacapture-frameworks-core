/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

public final class ListenerRegistry {
    public static let shared = ListenerRegistry()

    private final class EventSlot {
        var targets: Set<ListenerTarget> = []
        var attachments: [ListenerAttachment] = []
    }

    private let lock = NSRecursiveLock()
    private var handlers: [String: EventSlot] = [:]
    private var attachments: [ListenerAttachment] = []

    private init() {}

    public func register(attachment: ListenerAttachment) {
        var pending: [ListenerTarget] = []
        lock.lock()
        if attachments.contains(where: { $0 === attachment }) {
            lock.unlock()
            return
        }
        attachments.append(attachment)
        for eventName in attachment.eventNames {
            guard let slot = handlers[eventName] else { continue }
            if !slot.attachments.contains(where: { $0 === attachment }) {
                slot.attachments.append(attachment)
                pending.append(contentsOf: slot.targets)
            }
        }
        lock.unlock()
        var seen = Set<ListenerTarget>()
        pending.forEach { target in
            if seen.insert(target).inserted {
                attachment.attach(target: target)
            }
        }
    }

    public func unregister(attachment: ListenerAttachment) {
        var toDetach: [ListenerTarget] = []
        lock.lock()
        attachments.removeAll { $0 === attachment }
        for slot in handlers.values {
            let count = slot.attachments.count
            slot.attachments.removeAll { $0 === attachment }
            if slot.attachments.count != count {
                for target in slot.targets where !toDetach.contains(target) {
                    toDetach.append(target)
                }
            }
        }
        lock.unlock()
        toDetach.forEach { attachment.detach(target: $0) }
    }

    public func addListener(eventName: String, target: ListenerTarget) {
        Log.info("ListenerRegistry.addListener \(eventName) \(target.key)")
        var toAttach: [ListenerAttachment] = []
        lock.lock()
        let slot: EventSlot
        if let existing = handlers[eventName] {
            slot = existing
        } else {
            slot = EventSlot()
            slot.attachments = attachments.filter { $0.eventNames.contains(eventName) }
            handlers[eventName] = slot
        }
        if slot.targets.insert(target).inserted {
            toAttach = slot.attachments.filter { attachment in
                !attachment.eventNames.contains { other in
                    other != eventName && handlers[other]?.targets.contains(target) == true
                }
            }
        }
        lock.unlock()
        toAttach.forEach {
            Log.info("ListenerRegistry.attach \(eventName) \(target.key)")
            $0.attach(target: target)
        }
    }

    public func reattach(target: ListenerTarget) {
        var toAttach: [ListenerAttachment] = []
        lock.lock()
        for slot in handlers.values where slot.targets.contains(target) {
            for attachment in slot.attachments where !toAttach.contains(where: { $0 === attachment }) {
                toAttach.append(attachment)
            }
        }
        lock.unlock()
        toAttach.forEach {
            Log.info("ListenerRegistry.reattach \(target.key)")
            $0.attach(target: target)
        }
    }

    public func removeListener(eventName: String, target: ListenerTarget) {
        Log.info("ListenerRegistry.removeListener \(eventName) \(target.key)")
        var toDetach: [ListenerAttachment] = []
        lock.lock()
        guard let slot = handlers[eventName] else {
            lock.unlock()
            Log.info("No handlers found for event: \(eventName)")
            return
        }
        guard slot.targets.remove(target) != nil else {
            lock.unlock()
            Log.info("No handler found for event: \(eventName) with target: \(target.key)")
            return
        }
        toDetach = slot.attachments.filter { attachment in
            !attachment.eventNames.contains { other in
                handlers[other]?.targets.contains(target) == true
            }
        }
        if slot.targets.isEmpty { handlers.removeValue(forKey: eventName) }
        lock.unlock()
        toDetach.forEach {
            Log.info("ListenerRegistry.detach \(eventName) \(target.key)")
            $0.detach(target: target)
        }
    }

    public func removeAllListeners(target: ListenerTarget) {
        var toDetach: [ListenerAttachment] = []
        lock.lock()
        for (eventName, slot) in handlers {
            if slot.targets.remove(target) != nil {
                for attachment in slot.attachments where !toDetach.contains(where: { $0 === attachment }) {
                    toDetach.append(attachment)
                }
            }
            if slot.targets.isEmpty { handlers.removeValue(forKey: eventName) }
        }
        lock.unlock()
        toDetach.forEach { $0.detach(target: target) }
    }

    public func hasListeners(target: ListenerTarget) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return handlers.values.contains { $0.targets.contains(target) }
    }

    public func hasListeners(eventName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return handlers[eventName]?.targets.isEmpty == false
    }

    public func hasListeners(eventName: String, target: ListenerTarget) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return handlers[eventName]?.targets.contains(target) == true
    }

    public func reset() {
        var toDetach: [(ListenerAttachment, ListenerTarget)] = []
        lock.lock()
        for slot in handlers.values {
            for target in slot.targets {
                for attachment in slot.attachments
                where !toDetach.contains(where: { $0.0 === attachment && $0.1 == target }) {
                    toDetach.append((attachment, target))
                }
            }
        }
        handlers.removeAll()
        lock.unlock()
        toDetach.forEach { $0.0.detach(target: $0.1) }
    }
}
