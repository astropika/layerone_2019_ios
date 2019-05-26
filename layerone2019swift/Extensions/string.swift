//
//  string.swift
//  layerone2019swift
//


import Foundation
import CoreGraphics
import UIKit

extension String {

    func replace(target: String, withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: .literal, range: nil)
    }
    func drawFlipped(in rect: CGRect, withAttributes attributes: [NSAttributedString.Key : Any]) {
        guard let gc = UIGraphicsGetCurrentContext() else { return }
        gc.saveGState()
        defer { gc.restoreGState() }
        gc.translateBy(x: rect.origin.x, y: rect.origin.y + rect.size.height)
        gc.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(origin: .zero, size: rect.size), withAttributes: attributes)
    }
    
}
