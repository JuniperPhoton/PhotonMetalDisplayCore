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
    ///
    /// When in this mode, you must call ``MetalRenderer/requestChanged(displayedImage:)`` to trigger a redraw.
    case renderWhenDirty
}
