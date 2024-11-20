//
//  MetalRenderMode.swift
//  PhotonGPUImage
//
//  Created by JuniperPhoton on 2024/11/20.
//
/// Render mode for MetalView.
public enum MetalRenderMode {
    /// Render continuously at the specified frame rate.
    case continuous(fps: Int = 30)
    
    /// Render only when the view is dirty.
    case renderWhenDirty
}
