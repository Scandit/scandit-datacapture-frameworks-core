/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import UIKit

public protocol TappableView: UIView {
    var didTap: (() -> Void)? { get set }
    // Flag to track if animation is in progress
    var isAnimating: Bool { get set }
}

public class TapGestureRecognizerWithClosure: UITapGestureRecognizer {
    private let action: () -> Void

    public init(_ action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(execute))
    }

    @objc
    private func execute() {
        action()
    }
}
