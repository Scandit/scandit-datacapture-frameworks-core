/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import UIKit

public class TappableBase64ImageView: UIImageView, TappableView {
    // Used in React-Native, not needed for Capacitor/Cordova
    private var isAnimatingValue: Bool = false
    public override var isAnimating: Bool {
        get { isAnimatingValue }
        set { isAnimatingValue = newValue }
    }

    public struct JSON: Decodable {
        struct OptionsJSON: Decodable {
            // swiftlint:disable:next nesting
            struct SizeJSON: Decodable {
                let width: CGFloat
                let height: CGFloat
            }

            let size: SizeJSON?
            let scale: CGFloat?
        }

        let data: String
        let options: OptionsJSON
    }

    public var didTap: (() -> Void)?

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public init?(base64DataString: String) {
        let dataString = String(base64DataString.split(separator: ",")[1])

        guard let imageData = Data(base64Encoded: dataString) else {
            return nil
        }

        super.init(image: UIImage(data: imageData))
    }

    public convenience init?(viewJson: String?) {
        guard let viewJson = viewJson,
            let jsonData = viewJson.data(using: .utf8)
        else {
            return nil
        }

        guard let json = try? JSONDecoder().decode(JSON.self, from: jsonData) else {
            return nil
        }

        self.init(json: json)
    }

    public convenience init?(json: JSON) {
        self.init(base64DataString: json.data)

        if let size = json.options.size {
            frame.size = CGSize(width: size.width, height: size.height)
        }

        if let scale = json.options.scale {
            frame.size = CGSize(width: frame.size.width * scale, height: frame.size.height * scale)
        }

        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    @objc public func handleTap() {
        didTap?()
    }
}

typealias TrackedBarcodeView = TappableBase64ImageView
