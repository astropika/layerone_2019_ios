//  From https://github.com/acj/TimeLapseBuilder-Swift
//  TimeLapseBuilder30.swift
//
//  Created by Adam Jensen on 11/18/16.
//
//  NOTE: This implementation is written in Swift 3.0.

import AVFoundation
import UIKit

let kErrorDomain = "VideoBuilder"
let kFailedToStartAssetWriterError = 0
let kFailedToAppendPixelBufferError = 1

class VideoBuilder: NSObject {
    let photoURLs: [String]
    var videoWriter: AVAssetWriter?
    let size: CGSize
    let fps: Double
    
    init(photoURLs: [String], size: CGSize, fps: Double ) {
        self.size = size
        self.photoURLs = photoURLs
        self.fps = fps
    }
    
    func build(_ progress: @escaping ((Progress) -> Void), success: @escaping ((URL) -> Void), failure: @escaping ((NSError) -> Void)) {
        let inputSize = self.size
        let outputSize = self.size
        var error: NSError?
        
        let documentsPath = FileManager.default.temporaryDirectory
        let videoOutputURL =  documentsPath.appendingPathComponent("AssembledVideo.mov")
        
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}
        
        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mov)
        } catch let writerError as NSError {
            error = writerError
            videoWriter = nil
        }
        
        if let videoWriter = videoWriter {
            let videoSettings: [String : AnyObject] = [
                AVVideoCodecKey  : AVVideoCodecType.h264 as AnyObject,
                AVVideoWidthKey  : outputSize.width as AnyObject,
                AVVideoHeightKey : outputSize.height as AnyObject,
                //        AVVideoCompressionPropertiesKey : [
                //          AVVideoAverageBitRateKey : NSInteger(1000000),
                //          AVVideoMaxKeyFrameIntervalKey : NSInteger(16),
                //          AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel
                //        ]
            ]
            
            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            
            let sourceBufferAttributes = [
                (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
                (kCVPixelBufferWidthKey as String): Float(inputSize.width),
                (kCVPixelBufferHeightKey as String): Float(inputSize.height)] as [String : Any]
            
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoWriterInput,
                sourcePixelBufferAttributes: sourceBufferAttributes
            )
            
            assert(videoWriter.canAdd(videoWriterInput))
            videoWriter.add(videoWriterInput)
            
            if videoWriter.startWriting() {
                videoWriter.startSession(atSourceTime: CMTime.zero)
                assert(pixelBufferAdaptor.pixelBufferPool != nil)
                
                let media_queue = DispatchQueue(label: "mediaInputQueue")
                
                videoWriterInput.requestMediaDataWhenReady(on: media_queue) {
                    let fps = self.fps
                    let frameDuration = CMTimeMake(value: 1, timescale: Int32(round(fps)))
                    let currentProgress = Progress(totalUnitCount: Int64(self.photoURLs.count))
                    
                    var frameCount: Int64 = 0
                    var remainingPhotoURLs = [String](self.photoURLs)
                    
                    while videoWriterInput.isReadyForMoreMediaData && !remainingPhotoURLs.isEmpty {
                        let nextPhotoURL = remainingPhotoURLs.remove(at: 0)
                        let lastFrameTime = CMTimeMake(value: frameCount, timescale: Int32(round(fps)))
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        if !self.appendPixelBufferForImageAtURL(nextPhotoURL, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                            error = NSError(
                                domain: kErrorDomain,
                                code: kFailedToAppendPixelBufferError,
                                userInfo: ["description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer"]
                            )
                            
                            break
                        }
                        
                        frameCount += 1
                        
                        currentProgress.completedUnitCount = frameCount
                        progress(currentProgress)
                    }
                    
                    videoWriterInput.markAsFinished()
                    videoWriter.finishWriting {
                        if let error = error {
                            failure(error)
                        } else {
                            success(videoOutputURL)
                        }
                        
                        self.videoWriter = nil
                    }
                }
            } else {
                error = NSError(
                    domain: kErrorDomain,
                    code: kFailedToStartAssetWriterError,
                    userInfo: ["description": "AVAssetWriter failed to start writing"]
                )
            }
        }
        
        if let error = error {
            failure(error)
        }
    }
    
    func appendPixelBufferForImageAtURL(_ url: String, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        
        autoreleasepool {
            if let url = URL(string: url),
                let image = UIImage(fileURLWithPath:url),
                let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )
                
                if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
                    
                    appendSucceeded = pixelBufferAdaptor.append(
                        pixelBuffer,
                        withPresentationTime: presentationTime
                    )
                    
                    pixelBufferPointer.deinitialize(count: 1)
                } else {
                    NSLog("error: Failed to allocate pixel buffer from pool")
                }
                
                pixelBufferPointer.deallocate()
            }
        }
        
        return appendSucceeded
    }
    
    func fillPixelBufferFromImage(_ image: UIImage, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        
        context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
}
