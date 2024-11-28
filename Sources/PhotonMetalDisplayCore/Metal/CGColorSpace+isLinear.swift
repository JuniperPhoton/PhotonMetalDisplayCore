//
//  CGColorSpace+isLinear.swift
//  PhotonMetalDisplayCore
//
//  Created by JuniperPhoton on 2024/11/28.
//
import CoreGraphics

public extension CGColorSpace {
    /// Returns true if the color space is in linear space.
    ///
    /// If this ColorSpace is not created with `CGColorspace(name:)` method, this will return nil.
    var isLinear: Bool? {
        guard let name = self.name as? String else { return false }
        return name.lowercased().contains("linear")
    }
}
