//
//  uiimage.swift
//  layerone2019swift


import Foundation
import UIKit


extension UIImage {
    func save(_ path: URL) {
        try! self.pngData()?.write(to: path)
        print("saved image at \(path)")
    }
    // load from path
    convenience init?(fileURLWithPath url: URL, scale: CGFloat = 1.0) {
            do {
                let data = try Data(contentsOf: url)
                self.init(data: data, scale: scale)
            } catch {
                print("-- Error: \(error)")
                return nil
            }
    }
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat.pi)
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat.pi
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
        
        //   // Rotate the image context
        bitmap?.rotate(by: degreesToRadians(degrees))
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        bitmap?.scaleBy(x: yFlip, y: -1.0)
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
        
        bitmap?.draw(cgImage!, in: rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

    func croppedImage(cropRect: CGRect) -> UIImage {
        var cropZone = CGRect(x:cropRect.origin.x,
                              y: cropRect.origin.y,
                              width:cropRect.size.width,
                              height:cropRect.size.height)

    //    let result = OpenCVWrapper.toCrop(self,cropZone)
        let cutImageRef: CGImage = self.cgImage!.cropping(to:cropZone)!
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }
    static func emptyImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let fillColor = UIColor.yellow
        fillColor.setFill()
        context.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        context.drawPath(using: CGPathDrawingMode.fill)

        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }
}
