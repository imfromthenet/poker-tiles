//
//  ThumbnailCaptureOutput.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation
import ScreenCaptureKit
import AppKit
import OSLog

class ThumbnailCaptureOutput: NSObject, SCStreamOutput {
    private let completion: (NSImage?) -> Void
    private let lock = NSLock()
    private var _hasCompleted = false
    
    var hasCompleted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _hasCompleted
    }
    
    init(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        lock.lock()
        guard !_hasCompleted else { 
            lock.unlock()
            return 
        }
        _hasCompleted = true
        lock.unlock()
        
        Logger.thumbnails.debug("Received sample buffer for thumbnail capture")
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            Logger.thumbnails.error("Failed to get image buffer from sample")
            completion(nil)
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Logger.thumbnails.error("Failed to create CGImage from CIImage")
            completion(nil)
            return
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        Logger.thumbnails.debug("✓ Successfully created NSImage: \(nsImage.size.width, privacy: .public)x\(nsImage.size.height, privacy: .public)")
        completion(nsImage)
    }
}