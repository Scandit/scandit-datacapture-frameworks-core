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
    
    private var configuration: FramesHandlingConfiguration = FramesHandlingConfiguration(
        isFileSystemCacheEnabled: false, imageQuality: 100
    )

    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        workingDir = cacheDir.appendingPathComponent("sc_frames")
        
        deleteExistingWorkingDir()
        createWorkingDir()
    }
    
  
    public func configure(configuration: FramesHandlingConfiguration) {
        self.configuration = configuration
    }
    
    public func release() {
        cache.removeAllObjects()
        deleteExistingWorkingDir()
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
    
    private func saveImageAsPNG(frameId: String, image: UIImage?) -> String? {
        guard let inputImage = image else {
            return nil
        }
        
 
        let fileName = "\(frameId).jpeg"

        if let imageData = inputImage.jpegData(compressionQuality: CGFloat(self.configuration.imageQuality / 100)) {
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
