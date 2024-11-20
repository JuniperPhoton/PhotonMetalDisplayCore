//
//  MetalView.swift
//  PhotonCam
//
//  Created by Photon Juniper on 2023/10/27.
//
import SwiftUI
import MetalKit

/// MTKView wrapper for SwiftUI.
public struct MetalView: ViewRepresentable {
    @ObservedObject public var renderer: MetalRenderer
    
    public let renderMode: MetalRenderMode
    public let isOpaque: Bool
    public let prefersDynamicRange: MetalDynamicRange
    
    /// Construct the MetalView with the given renderer.
    ///
    /// - parameter renderer: The ``MetalRenderer`` to use for drawing.
    /// - parameter renderMode: The ``MetalRenderMode`` for the view.
    /// - parameter isOpaque: Whether the view is opaque.
    /// - parameter prefersDynamicRange: The preferred dynamic range for the view.
    ///
    /// Note: this view can only response to the ``prefersDynamicRange`` changes.
    public init(
        renderer: MetalRenderer,
        renderMode: MetalRenderMode,
        isOpaque: Bool = true,
        prefersDynamicRange: MetalDynamicRange = .sdr
    ) {
        self.renderer = renderer
        self.renderMode = renderMode
        self.isOpaque = isOpaque
        self.prefersDynamicRange = prefersDynamicRange
    }
    
    /// - Tag: MakeView
    public func makeView(context: Context) -> MTKView {
        let view = CustomMTKView(frame: .zero, device: renderer.device)
        view.prefersDynamicRange = prefersDynamicRange
        view.onBoundsChanged = { [weak view] bounds in
            guard let view else { return }
            
            switch renderMode {
            case .continuous(_):
                view.setNeedsDisplay(bounds)
            default:
                break
            }
        }
        
        switch renderMode {
        case .continuous(let fps):
            // Suggest to Core Animation, through MetalKit, how often to redraw the view.
            view.preferredFramesPerSecond = fps
            view.enableSetNeedsDisplay = false
            view.isPaused = false
        case .renderWhenDirty:
            view.enableSetNeedsDisplay = true
            view.isPaused = true
        }
        
        // Allow Core Image to render to the view using the Metal compute pipeline.
        view.framebufferOnly = false
        view.delegate = renderer
        
        if let layer = view.layer as? CAMetalLayer {
            layer.isOpaque = isOpaque
        }
        
        if #available(iOS 16.0, *) {
            view.setupLayerDynamicRange(range: prefersDynamicRange)
        }
        
        return view
    }
    
    public func updateView(_ view: MTKView, context: Context) {
        configure(view: view, using: renderer)
        view.setNeedsDisplay(view.bounds)
        
        if let CustomMTKView = view as? CustomMTKView {
            CustomMTKView.prefersDynamicRange = prefersDynamicRange
            if #available(iOS 16.0, *) {
                CustomMTKView.setupLayerDynamicRange()
            }
        }
    }
    
    private func configure(view: MTKView, using renderer: MetalRenderer) {
        view.delegate = renderer
    }
}

/// A MetalKit view that can detect bounds changes and can disable HDR display in some conditions.
private class CustomMTKView: MTKView {
    /// The closure to call when the bounds change.
    var onBoundsChanged: ((CGRect) -> Void)? = nil
    
    /// The preferred dynamic range for the view.
    var prefersDynamicRange: MetalDynamicRange = .sdr
    
    private var observer: HDRContentDisplayObserver!
    private var currentBounds: CGRect = .zero
    
    override init(frame frameRect: CGRect, device: (any MTLDevice)?) {
        super.init(frame: frameRect, device: device)
        
        observer = HDRContentDisplayObserver { [weak self] range in
            guard let self else { return }
            if #available(iOS 16.0, *) {
                setupLayerDynamicRange()
            }
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(iOS 16.0, *)
    func setupLayerDynamicRange() {
        switch observer.maximumDynamicRange {
        case .hdr:
            setupLayerDynamicRange(range: self.prefersDynamicRange)
        case .sdr:
            setupLayerDynamicRange(range: .sdr)
        }
    }
    
    @available(iOS 16.0, *)
    func setupLayerDynamicRange(range: MetalDynamicRange) {
        if let layer = self.layer as? CAMetalLayer {
            switch range {
            case .hdr:
                layer.wantsExtendedDynamicRangeContent = true
                layer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
                self.colorPixelFormat = MTLPixelFormat.rgba16Float
            case .sdr:
                layer.wantsExtendedDynamicRangeContent = false
                layer.colorspace = CGColorSpace(name: CGColorSpace.displayP3)
                self.colorPixelFormat = MTLPixelFormat.rgba8Unorm
                break
            }
        }
    }
    
#if canImport(UIKit)
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.currentBounds != self.bounds {
            self.currentBounds = self.bounds
            onBoundsChanged?(self.currentBounds)
        }
    }
#else
    override func layout() {
        super.layout()
        
        if self.currentBounds != self.bounds {
            self.currentBounds = self.bounds
            onBoundsChanged?(self.currentBounds)
        }
    }
#endif
}