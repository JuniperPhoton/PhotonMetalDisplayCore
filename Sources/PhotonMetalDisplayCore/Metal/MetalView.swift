//
//  MetalView.swift
//  PhotonCam
//
//  Created by Photon Juniper on 2023/10/27.
//
import SwiftUI
import MetalKit

/// MTKView wrapper for SwiftUI.
///
/// You construct this SwiftUI view using ``init(renderer:renderMode:isOpaque:prefersDynamicRange:)``,
/// passing the renderer and some other configurations.
///
/// ```swift
/// MetalView(
///     renderer: renderer,
///     renderMode: .renderWhenDirty,
///     prefersDynamicRange: .hdr
/// )
/// ```
///
/// When it's time to render the `CIImage`, you call the ``MetalRenderer/requestChanged(displayedImage:)`` method.
///
/// > Note: This view responds to the `UIApplication` scene phase changes,
/// when the app is not active, the underlying view to switch to SDR rendering mode.
/// To prepare your content to not apply HDR effect when in HDR rendering mode, you should observe
/// the event using ``HDRContentDisplayObserver``.
public struct MetalView: ViewRepresentable {
    @ObservedObject public var renderer: MetalRenderer
    
    /// Get the render mode set for the view.
    public let renderMode: MetalRenderMode
    
    /// Get whether the view is opaque.
    public let isOpaque: Bool
    
    /// Get the preferred dynamic range set for the view.
    public let prefersDynamicRange: MetalDynamicRange
    
    /// The clear color for the view.
    public let clearColor: MetalViewClearColor?
    
    /// Construct the MetalView with the given renderer.
    ///
    /// - parameter renderer: The ``MetalRenderer`` to use for drawing.
    /// - parameter renderMode: The ``MetalRenderMode`` for the view.
    /// - parameter isOpaque: Whether the view is opaque. The default value is true.
    /// - parameter prefersDynamicRange: The preferred dynamic range for the view.
    /// The default value is ``MetalDynamicRange/sdr``.
    /// - parameter clearColor: The clear color for the view. The default value is nil, clearing to Black.
    /// Note: Setting this on macOS will not work currently.
    ///
    /// Note: this view can only response to the ``prefersDynamicRange`` changes.
    /// ``renderer``, ``renderMode`` and ``isOpaque`` must be confirmed when initializing this view.
    public init(
        renderer: MetalRenderer,
        renderMode: MetalRenderMode,
        isOpaque: Bool = true,
        prefersDynamicRange: MetalDynamicRange = .sdr,
        clearColor: MetalViewClearColor? = nil
    ) {
        self.renderer = renderer
        self.renderMode = renderMode
        self.isOpaque = isOpaque
        self.prefersDynamicRange = prefersDynamicRange
        self.clearColor = clearColor
    }
    
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
        
        if let clearColor {
#if canImport(UIKit)
            view.clearColor = clearColor.mtlColor
            view.backgroundColor = clearColor.platformColor
#endif
        }
        
        if let customMTKView = view as? CustomMTKView {
            customMTKView.prefersDynamicRange = prefersDynamicRange
            if #available(iOS 16.0, *) {
                customMTKView.setupLayerDynamicRange()
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
    
#if canImport(UIKit)
    private var observer: HDRContentDisplayObserver!
#endif
    
    private var currentBounds: CGRect = .zero
    
    override init(frame frameRect: CGRect, device: (any MTLDevice)?) {
        super.init(frame: frameRect, device: device)
        
#if canImport(UIKit)
        observer = HDRContentDisplayObserver { [weak self] range in
            guard let self else { return }
            if #available(iOS 16.0, *) {
                setupLayerDynamicRange()
            }
        }
#endif
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(iOS 16.0, *)
    func setupLayerDynamicRange() {
#if canImport(UIKit)
        switch observer.maximumDynamicRange {
        case .hdr:
            setupLayerDynamicRange(range: self.prefersDynamicRange)
        case .sdr:
            setupLayerDynamicRange(range: .sdr)
        }
#else
        setupLayerDynamicRange(range: self.prefersDynamicRange)
#endif
    }
    
    @available(iOS 16.0, *)
    func setupLayerDynamicRange(range: MetalDynamicRange) {
        if let layer = self.layer as? CAMetalLayer {
            switch range {
            case .hdr:
                // To support HDR display, setting both `wantsExtendedDynamicRangeContent` and `colorPixelFormat` is enough.
                // Internally it will check `wantsExtendedDynamicRangeContent` and `colorPixelFormat`
                // to choose a proper color space, which can be inspected later when drawing.
                layer.wantsExtendedDynamicRangeContent = true
                self.colorPixelFormat = MTLPixelFormat.rgba16Float
            case .sdr:
                layer.wantsExtendedDynamicRangeContent = false
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

extension MTKView {
    var layerColorSpace: CGColorSpace? {
        if let layer = self.layer as? CAMetalLayer {
            return layer.colorspace
        } else {
            return nil
        }
    }
}
