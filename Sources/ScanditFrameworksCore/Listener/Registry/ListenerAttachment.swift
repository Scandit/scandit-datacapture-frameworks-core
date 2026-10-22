/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

public protocol ListenerAttachment: AnyObject {
    var eventNames: Set<String> { get }

    func attach(target: ListenerTarget)

    func detach(target: ListenerTarget)
}

public final class ModuleListenerAttachment: ListenerAttachment {
    public let eventNames: Set<String>
    private let attachFn: (ListenerTarget) -> Void
    private let detachFn: (ListenerTarget) -> Void

    private init(
        eventNames: Set<String>,
        attach: @escaping (ListenerTarget) -> Void,
        detach: @escaping (ListenerTarget) -> Void
    ) {
        self.eventNames = eventNames
        self.attachFn = attach
        self.detachFn = detach
    }

    public func attach(target: ListenerTarget) {
        attachFn(target)
    }

    public func detach(target: ListenerTarget) {
        detachFn(target)
    }

    public static func global(
        _ eventNames: Set<String>,
        attach: @escaping () -> Void,
        detach: @escaping () -> Void
    ) -> ListenerAttachment {
        ModuleListenerAttachment(
            eventNames: eventNames,
            attach: { if case .global = $0 { attach() } },
            detach: { if case .global = $0 { detach() } }
        )
    }

    public static func forMode(
        _ eventNames: Set<String>,
        attach: @escaping (Int) -> Void,
        detach: @escaping (Int) -> Void
    ) -> ListenerAttachment {
        ModuleListenerAttachment(
            eventNames: eventNames,
            attach: { if case .mode(let id) = $0 { attach(id) } },
            detach: { if case .mode(let id) = $0 { detach(id) } }
        )
    }

    public static func forView(
        _ eventNames: Set<String>,
        attach: @escaping (Int) -> Void,
        detach: @escaping (Int) -> Void
    ) -> ListenerAttachment {
        ModuleListenerAttachment(
            eventNames: eventNames,
            attach: { if case .view(let id) = $0 { attach(id) } },
            detach: { if case .view(let id) = $0 { detach(id) } }
        )
    }
}
