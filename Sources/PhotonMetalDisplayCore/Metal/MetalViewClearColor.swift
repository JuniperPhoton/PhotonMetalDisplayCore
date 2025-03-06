//
//  MetalViewClearColor.swift
//  PhotonMetalDisplayCore
//
//  Created by JuniperPhoton on 2025/3/7.
//
import SwiftUI

#if canImport(UIKit)
public typealias MTLPlatformColor = UIColor
#else
public typealias MTLPlatformColor = NSColor
#endif

/// Represents a `MTLClearColor` and a platform color.
public struct MetalViewClearColor {
    let mtlColor: MTLClearColor
    let platformColor: MTLPlatformColor
    
    public init(mtlColor: MTLClearColor, platformColor: MTLPlatformColor) {
        self.mtlColor = mtlColor
        self.platformColor = platformColor
    }
}

public extension MTLClearColor {
    /// The clear color for `MTLClearColor`.
    static let clear = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
}
