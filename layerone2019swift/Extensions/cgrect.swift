//
//  cgrect.swift
//  layerone2019swift


import Foundation
import CoreGraphics

extension CGRect {
    public func rotated(degrees: CGFloat) -> CGRect {
        
    let radiansToDegrees: (CGFloat) -> CGFloat = {
        return $0 * (180.0 / CGFloat.pi)
    }
    let degreesToRadians: (CGFloat) -> CGFloat = {
        return $0 / 180.0 * CGFloat.pi
    }
        
    let rectCenter = CGPoint(x: self.width/2, y: self.height/2)
    var transform = CGAffineTransform(translationX: rectCenter.x, y: rectCenter.y)
    transform = transform.rotated(by: degreesToRadians(degrees))
        
    return self.applying(transform)
}
}
