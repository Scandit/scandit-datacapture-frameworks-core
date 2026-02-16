/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation

extension CGPoint {
    var jsonString: String {
        """
        {"x": \(x), "y": \(y)}
        """
    }

    init?(json: String) {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let pointDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: CGFloat] else {
            return nil
        }
        guard let x = pointDict["x"], let y = pointDict["y"] else { return nil }

        self.init(x: x, y: y)
    }
}
