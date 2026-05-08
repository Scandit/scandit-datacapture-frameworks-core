/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public final class LastFrameData {
    public static let shared = LastFrameData()

    private var workingDir: URL

    private let cache: FrameDataCache = FrameDataCache()

    private var configuration: FramesHandlingConfiguration = FramesHandlingConfiguration.createDefaultConfiguration()

    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        workingDir = cacheDir.appendingPathComponent("sc_frames")

        deleteExistingWorkingDir()
        createWorkingDir()
    }

    public var isFileSystemCacheEnabled: Bool {
        configuration.isFileSystemCacheEnabled
    }


    public func configure(configuration: FramesHandlingConfiguration) {
        self.configuration = configuration
    }

    public func release() {
        cache.removeAllObjects()
        deleteExistingWorkingDir()
        createWorkingDir()
    }

    public func addToCache(frameData: FrameData) -> String {
        let id = UUID().uuidString
        cache.addFrame(frameData, forId: id)
        return id
    }

    public func removeFromCache(frameId: String) {
        cache.removeFrame(forId: frameId)
    }

    public func getLastFrameDataJSON(frameId: String, result: @escaping (String?) -> Void) {
        guard let frameData = cache.getFrame(forId: frameId) else {
            result(nil)
            return
        }

        if (self.configuration.isFileSystemCacheEnabled) {
            let encodedJson = getEncodableFrameData(frameId: frameId, data: frameData).encodeToJSONString()
            result(encodedJson)
            return
        }

        result(frameData.jsonString)
    }

    public func getLastFrameDataBytes(frameId: String, result: @escaping ([String: Any?]?) -> Void) {
        guard let frameData = cache.getFrame(forId: frameId) else {
            result(nil)
            return
        }

        result(getEncodableFrameData(frameId: frameId, data: frameData))
    }

    private func deleteExistingWorkingDir() {
        if FileManager.default.fileExists(atPath: workingDir.path) {
            do {
                try FileManager.default.removeItem(at: workingDir)
            } catch {
                Log.error("Error deleting the frames working directory", error: error)
            }
        }
    }

    private func createWorkingDir() {
        do {
            try FileManager.default.createDirectory(
                at: workingDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            Log.error("Error creating the frames working directory", error: error)
        }
    }

    public func saveImageToFile(image: UIImage) -> String? {
        let frameId = UUID().uuidString
        return saveImageAsPNG(frameId: frameId, image: image)
    }

    private func saveImageAsPNG(frameId: String, image: UIImage?) -> String? {
        guard let inputImage = image else {
            return nil
        }

        // Only rotate if autoRotateImages is enabled, otherwise use original image
        let imageToSave = configuration.autoRotateImages ? inputImage.rotate(by: 90) : inputImage

        let fileName = "\(frameId).jpeg"

        if let imageData = imageToSave.jpegData(compressionQuality: CGFloat(self.configuration.imageQuality / 100)) {
            let fileURL = workingDir.appendingPathComponent(fileName)

            do {
                try imageData.write(to: fileURL)
                return fileURL.absoluteString.replacingOccurrences(of: "file://", with: "")
            } catch {
                Log.error("Error saving the frame to file.", error: error)
            }
        }

        return nil
    }

    private func getEncodableImageBuffer(frameId: String, buffer: ImageBuffer) ->  [String: Any?] {
        var encodedData: [String: Any?] = [
          "width": buffer.width,
          "height": buffer.height
        ]

        if (self.configuration.isFileSystemCacheEnabled) {
            encodedData["data"] = saveImageAsPNG(frameId: frameId, image: buffer.image)
        } else {
            encodedData["data"] = buffer.image?.pngData()
        }

        return encodedData
    }

    private func getEncodableFrameData(frameId: String, data: FrameData) ->  [String: Any?] {
        return  [
            "imageBuffers": data.imageBuffers.compactMap { getEncodableImageBuffer(frameId: frameId, buffer: $0) },
            "orientation": 90,
        ]
    }

}

private class FrameDataCache {
    private let cache: NSCache<NSString, FrameData> = {
        let cache = NSCache<NSString, FrameData>()
        cache.countLimit = 2 // Set the maximum number of objects the cache can hold
        return cache
    }()

    private let cacheQueue = DispatchQueue(label: "com.scandit.frameworks.lastframedata-queue")

    func addFrame(_ object: FrameData, forId frameId: String) {
        cacheQueue.sync {
            cache.setObject(object, forKey: frameId as NSString)
        }
    }

    func getFrame(forId frameId: String) -> FrameData? {
        return cacheQueue.sync {
            let frameData = cache.object(forKey: frameId as NSString)
            if (frameData != nil) {
                cache.removeObject(forKey: frameId as NSString)
            }
            return frameData
        }
    }

    func removeFrame(forId frameId: String) {
        cacheQueue.sync {
            cache.removeObject(forKey: NSString(string: frameId))
        }
    }

    func removeAllObjects() {
        cacheQueue.sync {
            cache.removeAllObjects()
        }
    }
}


fileprivate extension UIImage {
    func rotate(by degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size

        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            cgContext.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }
}
