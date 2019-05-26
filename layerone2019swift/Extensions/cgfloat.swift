//
//  cgfloat.swift
//  layerone2019swift

import Foundation
import CoreGraphics

extension CGFloat {
    var degrees: CGFloat {
        return self * CGFloat(180.0 / .pi)
    }
}
