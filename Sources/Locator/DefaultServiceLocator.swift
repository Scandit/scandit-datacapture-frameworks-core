/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class DefaultServiceLocator: ServiceLocator {
    public typealias T = FrameworkModule

    private var services: [String: FrameworkModule] = [:]
    private let queue = DispatchQueue(
        label: "com.scandit.frameworks.DefaultServiceLocatorQueue"
    )

    public static let shared = DefaultServiceLocator()

    private init() {}

    public func register(module: FrameworkModule) {
        queue.sync {
            let className = String(describing: type(of: module))
            services[className] = module
        }
    }

    public func resolve(clazzName: String) -> FrameworkModule? {
        queue.sync {
            services[clazzName]
        }
    }

    public func remove(clazzName: String) -> FrameworkModule? {
        queue.sync {
            services.removeValue(forKey: clazzName)
        }
    }

    public func removeAll() {
        queue.sync {
            services.removeAll()
        }
    }
}
