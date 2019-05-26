//
//  FaceDetector.swift
//  layerone2019swift

import Foundation
import UIKit
import Vision
import GPUImage

class FaceDetector {
    
    open func showEye(for source: UIImage, complete: @escaping (UIImage) -> Void) {
        var resultImage = source
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if error == nil {
                if let results = request.results as? [VNFaceObservation] {
                    print("Found \(results.count) faces")
                    if (results.count < 1){
                        stream.hideImageView()
                        complete(resultImage)
                    }
                    else {
                        var eyes = [CGRect]()
                        for faceObservation in results {
                            guard let landmarks = faceObservation.landmarks else {
                                continue
                            }
                            //let uuid = faceObservation.uuid
                            
                            if faceObservation.confidence < 0.5 {
                                return
                            }
                            let boundingRect = faceObservation.boundingBox
                            var landmarkRegions: [VNFaceLandmarkRegion2D] = []
                            if let leftEye = landmarks.leftEye {
                                landmarkRegions.append(leftEye)
                                if let leftPupil = landmarks.leftPupil {
                                    landmarkRegions.append(leftPupil)
                                }
                            }
                            if let rightEye = landmarks.rightEye {
                                landmarkRegions.append(rightEye)
                                if let rightPupil = landmarks.rightPupil {
                                    landmarkRegions.append(rightPupil)
                                }
                            }
                            if landmarkRegions.count < 1 {
                                return
                            }
                            // making eyebox a square
                            var eyebox = self.landmarkToBoundsUi(source: source, boundingRect: boundingRect, landmark: landmarkRegions[0] )
                            var diff: CGFloat
                            
                            let lefteye = landmarks.leftEye
                            let righteye = landmarks.rightEye
                            var rotation = CGFloat(0.0)
                            
                            if lefteye != nil && (righteye != nil) {
                                let leftbox = self.landmarkToBounds(source: source, boundingRect: boundingRect, landmark: lefteye! )
                                let rightbox = self.landmarkToBounds(source: source, boundingRect: boundingRect, landmark: righteye! )
                                rotation = self.find_orientation(leftbox: leftbox, rightbox: rightbox)
                            }

                            
                            if eyebox.width > eyebox.height {
                                diff = eyebox.width-eyebox.height
                                eyebox = eyebox.insetBy(dx:0.0, dy:-(diff/2))
                            }
                            if eyebox.width < eyebox.height {
                                diff = eyebox.height-eyebox.width
                                eyebox = eyebox.insetBy(dx:-(diff/2),dy:0.0)
                            }

                        /*    let newbox = CGRect(x: eyebox.origin.x - eyebox.width/2, y: eyebox.origin.y - eyebox.height/2, width: eyebox.width * 2, height:eyebox.height * 2 )*/
                            
                            eyes.append(eyebox)
                            
                         //   resultImage = resultImage.imageRotatedByDegrees(degrees: rotation, flip: false)
                            //   let pupil = OpenCVWrapper.getPupil(resultImage)
                            // print(pupil)
                        }
                        let largesteye = eyes.max {a, b in a.width < b.width  }
                        if largesteye != nil {
                            resultImage = resultImage.croppedImage(cropRect:largesteye!)
                            stream.showImageView()
                        }
                        else {
                            stream.hideImageView()
                        }
                    }
                } else {
                    resultImage = self.drawStatic(source: source)
                    print(error!.localizedDescription)
                }
                complete(resultImage)
            }
            
        }
        let vnImage = VNImageRequestHandler(cgImage: source.cgImage!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }
    
    open func drawFeatures(for source: UIImage, complete: @escaping (UIImage) -> Void) {
        var resultImage = source
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if error == nil {
                if let results = request.results as? [VNFaceObservation] {
                    print("Found \(results.count) faces")
                    for faceObservation in results {
                        guard let landmarks = faceObservation.landmarks else {
                            continue
                        }
                        let boundingRect = faceObservation.boundingBox
                        var landmarkRegions: [VNFaceLandmarkRegion2D] = []
                        if let leftEye = landmarks.leftEye {
                            landmarkRegions.append(leftEye)
                        }
                        if let rightEye = landmarks.rightEye {
                            landmarkRegions.append(rightEye)
                        }
                        if let leftPupil = landmarks.leftPupil {
                            landmarkRegions.append(leftPupil)
                        }
                        if let rightPupil = landmarks.rightPupil {
                            landmarkRegions.append(rightPupil)
                        }
                        if let medianLine = landmarks.medianLine {
                            landmarkRegions.append(medianLine)
                        }
                        if let outerLips = landmarks.outerLips {
                            landmarkRegions.append(outerLips)
                        }
                        
                        
                        // making eyebox a square
                        var eyebox = self.landmarkToBounds(source: source, boundingRect: boundingRect, landmark: landmarkRegions[0] )
                        
                        var diff: CGFloat
                        if eyebox.width > eyebox.height {
                            diff = eyebox.width-eyebox.height
                            eyebox = eyebox.insetBy(dx:0.0, dy:-(diff/2))
                        }
                        if eyebox.width < eyebox.height {
                            diff = eyebox.height-eyebox.width
                            eyebox = eyebox.insetBy(dx:-(diff/2),dy:0.0)
                        }
                        
                        resultImage = self.drawOnImage(source: resultImage, boundingRect: boundingRect, roiRect: eyebox, faceLandmarkRegions: landmarkRegions )
                    }
                }
            } else {
                print(error!.localizedDescription)
            }
            complete(resultImage)
        }
        let vnImage = VNImageRequestHandler(cgImage: source.cgImage!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }
    
    
    open func highlightFaces(for source: UIImage, complete: @escaping (UIImage) -> Void) {
        var resultImage = source
        let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if error == nil {
                if let results = request.results as? [VNFaceObservation] {
                    print("Found \(results.count) faces")
                    for faceObservation in results {
                        let boundingRect = faceObservation.boundingBox
                        let baseimage = self.drawFaceBox(source: source, boundingRect: boundingRect )
                        resultImage = baseimage                        
                    }
                }
            } else {
                print(error!.localizedDescription)
            }
            complete(resultImage)
        }
        let vnImage = VNImageRequestHandler(cgImage: source.cgImage!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }
    
    
    open func getFaces(for source: UIImage, complete: @escaping ([VNFaceObservation],UIImage) -> Void) {
        let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if error == nil {
                if let results = request.results as? [VNFaceObservation] {
                    complete(results, source);
                }
            }
        }
        let vnImage = VNImageRequestHandler(cgImage: source.cgImage!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }
    
    open func drawStatic(source: UIImage) -> UIImage
    {
        let image = UIImage.emptyImage(with: source.size)!
        return image
    }
    
    func landmarkToBounds(source: UIImage,
                                      boundingRect: CGRect,
                                      landmark: VNFaceLandmarkRegion2D) -> CGRect
    {
        let path = CGMutablePath()
        var points = landmark.pointsInImage(imageSize: source.size)
        
        path.addLines(between: points)
        return path.boundingBox
    }
    
    func landmarkToBoundsUi(source: UIImage,
                                        boundingRect: CGRect,
                                        landmark: VNFaceLandmarkRegion2D) -> CGRect
    {
        
        let path = CGMutablePath()
        var points = landmark.pointsInImage(imageSize: source.size)
        
        path.addLines(between: points)
        let box = path.boundingBox
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -source.size.height)
        return box.applying(transform)
    }
    
    
    
    func drawOnImage( source: UIImage,
                                 boundingRect: CGRect,
                                 roiRect: CGRect,
                                 faceLandmarkRegions: [VNFaceLandmarkRegion2D]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height
        
        
        //draw image
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)
        
        
        //draw bound rect
        var fillColor = UIColor.green
        fillColor.setFill()
        context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        // draw roi rect
        
        fillColor = UIColor.yellow
        fillColor.setFill()
        context.addRect(CGRect(x: roiRect.origin.x, y:roiRect.origin.y, width: roiRect.width, height: roiRect.height))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        fillColor = UIColor.red
        fillColor.setStroke()
        context.setLineWidth(5.0)
        
        if config.debug {
        var cross_x = [CGPoint]()
        var cross_y = [CGPoint]()
        
         //draw image center
         cross_x.append(CGPoint(x:(source.size.width/2)-50, y:source.size.height/2))
         cross_x.append(CGPoint(x:(source.size.width/2)+50, y:source.size.height/2))
         context.addLines(between: cross_x)
         
         cross_y.append(CGPoint(x:source.size.width/2, y:(source.size.height/2)-50 ))
         cross_y.append(CGPoint(x:source.size.width/2, y:(source.size.height/2)+50 ))
         
         context.addLines(between: cross_y)
         context.drawPath(using: CGPathDrawingMode.stroke)
        }
        
        var coords = [(Int,Int)]()
        //draw overlay
        fillColor = UIColor.red
        fillColor.setStroke()
        context.setLineWidth(2.0)
        for faceLandmarkRegion in faceLandmarkRegions {
            let featrect =
                self.landmarkToBounds(source: source, boundingRect: boundingRect, landmark: faceLandmarkRegion)
                coords.append((Int(featrect.origin.x),Int(featrect.origin.y)))
            
            var points: [CGPoint] = []
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.normalizedPoints[i]
                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                points.append(p)
            }
            let mappedPoints = points.map { CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: boundingRect.origin.y * source.size.height + $0.y * rectHeight) }
            context.addLines(between: mappedPoints)
            context.drawPath(using: CGPathDrawingMode.stroke)
        }
        if config.debug {
            label_coord(coords: coords)
        }
        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }
    
    fileprivate func find_orientation(leftbox: CGRect, rightbox: CGRect ) -> CGFloat
    {
        let leftright = CGPoint(x: leftbox.origin.x, y: leftbox.origin.y).angle(to: CGPoint(x: rightbox.origin.x, y: rightbox.origin.y) )
        
        return leftright
    }
    
    fileprivate func label_coord(coords: [(Int,Int)]) {
        //debug positions
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 24.0),
            .foregroundColor: UIColor.blue
        ]
        for coord in coords {
            let string = "\(coord.0),\(coord.1)"
            let stringRect = CGRect(x: coord.0, y: coord.1, width:120, height:50)
            string.drawFlipped(in: stringRect, withAttributes: attributes)
        }
    }
    
    fileprivate func drawFaceBox(source: UIImage,
                                 boundingRect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height
        
        //draw image
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)
        
        
        //draw bound rect
        var fillColor = UIColor.green
        fillColor.setFill()
        context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        // draw roi rect
        
        fillColor = UIColor.yellow
        fillColor.setFill()
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }
    
}
