//
//  Renderer.swift
//  PhotonCam
//
//  Created by Photon Juniper on 2023/10/27.
//

import Foundation
import Metal
import MetalKit
import CoreImage

private let maxBuffersInFlight = 3

/// A renderer that renders a CIImage to a ``MetalView``.
///
/// You must call ``initializeCIContext(colorSpace:name:queue:)`` before using this renderer.
///
/// > Note: ``initializeCIContext(colorSpace:name:queue:)`` may takes time, and you can call it off the main thread.
///
/// ## Rendering
///
/// You use ``requestChanged(displayedImage:)`` to update the image to be drawn.
///
/// If images with different aspect ratios will be drawn, you should call the ``requestClearDestination(clearDestination:)`` passing true,
/// which will clear the previous rendering destination before rendering the new image.
///
/// ## Background
///
/// You can use ``setBackgroundColor(ciColor:)`` or ``setBackgroundImage(_:)`` to set the background color or image.
public final class MetalRenderer: NSObject, MTKViewDelegate, ObservableObject {
    /// Get the last requested time to display the image.
    /// When rendering in ``MetalRenderMode/renderWhenDirty``, you can use this to decide when to update the image.
    @Published private(set) var requestedDisplayedTime = CFAbsoluteTimeGetCurrent()
    
    /// The Metal device used to render the image.
    let device: MTLDevice
    
    /// Get whether the debug mode is on.
    public private(set) var debugMode = false
    
    /// The options used to create the CIContext.
    /// You can use this to retrieve information like the working color space.
    public private(set) var ciContextOptions: [CIContextOption: Any]? = nil
    
    /// Get the CIContext used to render the image.
    ///
    /// You use the ``initializeCIContext(options:queue:)`` to initialize this CIContext.
    public private(set) var ciContext: CIContext? = nil
    
    private let commandQueue: MTLCommandQueue
    private var opaqueBackground: CIImage
    
    private let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    private(set) var scaleToFill: Bool = false
    
    private var displayedImage: CIImage? = nil
    private var queue: DispatchQueue? = nil
    
    private var clearDestination: Bool = false
    
    /// The delegate to receive the render events.
    public weak var eventDelegate: MetalRenderEventsDelegate? = nil
    
    public override init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        self.opaqueBackground = CIImage.black
        super.init()
    }
    
    /// Set the debug mode. By setting this true while in debug build,
    /// additional information will be printed to the console.
    ///
    /// You can also inspect the `CIRenderInfo` in the following source code to see the render graph.
    ///
    /// ![](debug-inspect.jpg)
    ///
    /// ```swift
    /// let info = try? task?.waitUntilCompleted()
    /// print("Render task completed: \(String(describing: info))")
    /// ```
    ///
    /// - parameter on: If the debug mode is on.
    ///
    /// > Note: This method does nothing in release build.
    public func setDebugMode(_ on: Bool) {
#if DEBUG
        self.debugMode = on
#else
        self.debugMode = false
#endif
    }
    
    /// The the background color to be composited over with.
    /// If the color is not opaque, please remember to set ``MetalView/isOpaque`` in ``MetalView``.
    public func setBackgroundColor(ciColor: CIColor) {
        setBackgroundImage(CIImage(color: ciColor))
    }
    
    /// The the background image to be composited over with.
    public func setBackgroundImage(_ image: CIImage) {
        self.opaqueBackground = image
    }
    
    /// Set whether to scale to fill the content.
    public func setScaleToFill(scaleToFill: Bool) {
        self.scaleToFill = scaleToFill
    }
    
    /// Initialize the CIContext with some options.
    /// - parameter options: The options to create the CIContext.
    /// - parameter queue: A dedicated queue to start the render task. Although the whole render process is run by GPU,
    /// however creating and submitting textures to GPU will introduce performance overhead, and it's recommended not to do it on main thread.
    @_spi(Internal)
    public func initializeCIContext(
        options: [CIContextOption : Any]? = nil,
        queue: DispatchQueue? = DispatchQueue(label: "metal_render_queue", qos: .userInitiated)
    ) {
        eventDelegate?.onStartInitializeCIContext()
        self.queue = queue
        self.ciContext = CIContext(
            mtlCommandQueue: self.commandQueue,
            options: options
        )
        self.ciContextOptions = options
        eventDelegate?.onStopInitializeCIContext()
    }
    
    /// Initialize the CIContext with a specified working `CGColorSpace`.
    /// - parameter colorSpace: The working Color Space to use.
    /// - parameter name: The name of the CIContext. This is used for debugging purposes.
    /// - parameter queue: A dedicated queue to start the render task. Although the whole render process is run by GPU,
    /// however creating and submitting textures to GPU will introduce performance overhead, and it's recommended not to do it on main thread.
    public func initializeCIContext(
        colorSpace: CGColorSpace?,
        name: String,
        queue: DispatchQueue? = DispatchQueue(label: "metal_render_queue", qos: .userInitiated)
    ) {
        eventDelegate?.onStartInitializeCIContext()

        self.queue = queue
        
        // Set up the Core Image context's options:
        // - Name the context to make CI_PRINT_TREE debugging easier.
        // - Disable caching because the image differs every frame.
        // - Allow the context to use the low-power GPU, if available.
        var options = [CIContextOption: Any]()
        options = [
            .name: name,
            .cacheIntermediates: false,
            .allowLowPower: true,
        ]
        if let colorSpace = colorSpace {
            options[.workingColorSpace] = colorSpace
        }
        
        self.ciContext = CIContext(
            mtlCommandQueue: self.commandQueue,
            options: options
        )
        
        self.ciContextOptions = options
        
        LibLogger.default.log("MetalRenderer initializeCIContext name: \(name) with working color space: \(String(describing: colorSpace))")
        eventDelegate?.onStopInitializeCIContext()
    }
    
    /// Request update the image.
    ///
    /// The image will be rendered in the next frame.
    ///
    /// - parameter displayedImage: The CIImage to be rendered.
    public func requestChanged(displayedImage: CIImage?) {
        self.displayedImage = displayedImage
        self.requestedDisplayedTime = CFAbsoluteTimeGetCurrent()
    }
    
    /// Request clear the destination.
    /// - parameter clearDestination: If the destination should be cleared first before starting a new task to render image.
    public func requestClearDestination(clearDestination: Bool) {
        self.clearDestination = clearDestination
    }
    
    // MARK: MTKViewDelegate
    public func draw(in view: MTKView) {
        drawInternal(view)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Respond to drawable size or orientation changes.
    }
    
    /// Draw the content into the view's texture.
    private func drawInternal(_ view: MTKView) {
        guard let ciContext = self.ciContext else {
            LibLogger.default.log("CIContext is nil!")
            return
        }
        
        // Create a displayable image for the current time.
        guard var image = self.displayedImage else {
            return
        }
                
        _ = self.inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        if let commandBuffer = self.commandQueue.makeCommandBuffer() {
            // Add a completion handler that signals `inFlightSemaphore` when Metal and the GPU have fully
            // finished processing the commands that the app encoded for this frame.
            // This completion indicates that Metal and the GPU no longer need the dynamic buffers that
            // Core Image writes to in this frame.
            // Therefore, the CPU can overwrite the buffer contents without corrupting any rendering operations.
            let semaphore = self.inFlightSemaphore
            commandBuffer.addCompletedHandler { _ in
                semaphore.signal()
            }
            
            if let eventDelegate {
                let startTime = CFAbsoluteTimeGetCurrent()
                let id = String(startTime)
                eventDelegate.onStartRender(id: id)
                
                commandBuffer.addCompletedHandler { [weak eventDelegate] _ in
                    eventDelegate?.onEndRender(id: id)
                }
            }
            
            if let drawable = view.currentDrawable {
                let dSize = view.drawableSize
                
                // Create a destination the Core Image context uses to render to the drawable's Metal texture.
                let destination = CIRenderDestination(
                    width: Int(dSize.width),
                    height: Int(dSize.height),
                    pixelFormat: view.colorPixelFormat,
                    commandBuffer: nil
                ) {
                    return drawable.texture
                }
                
                let scaleW = CGFloat(dSize.width) / image.extent.width
                let scaleH = CGFloat(dSize.height) / image.extent.height
                
                let shiftX: CGFloat
                let shiftY: CGFloat
                let scale: CGFloat
                let iRect: CGRect
                let backBounds = CGRect(x: 0, y: 0, width: dSize.width, height: dSize.height)
                
                if self.scaleToFill {
                    scale = max(scaleW, scaleH)
                    
                    image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                        .transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))
                    iRect = image.extent
                    
                    let offsetX = round((backBounds.size.width - iRect.width) * 0.5)
                    let offsetY = round((backBounds.size.height - iRect.height) * 0.5)
                    
                    image = image.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
                    image = image.cropped(to: backBounds)
                    
                    shiftX = 0.0
                    shiftY = 0.0
                } else {
                    scale = min(scaleW, scaleH)
                    
                    let originalExtent = image.extent
                    let scaledWidth = Int(originalExtent.width * scale)
                    let scaledHeight = Int(originalExtent.height * scale)
                    image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                    image = image.cropped(to: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
                    
                    // Center the image in the view's visible area.
                    iRect = image.extent
                    image = image.cropped(to: backBounds)
                    
                    shiftX = round((backBounds.size.width + iRect.origin.x - iRect.size.width) * 0.5)
                    shiftY = round((backBounds.size.height + iRect.origin.y - iRect.size.height) * 0.5)
                }
                
                // Blend the image over an opaque background image.
                // This is needed if the image is smaller than the view, or if it has transparent pixels.
                image = image.composited(over: self.opaqueBackground)
                
                let block = {
                    if self.clearDestination {
                        _ = try? ciContext.startTask(toClear: destination)
                    }
                    
                    // Start a task that renders to the texture destination.
                    // To prevent showing clamped content outside of the image's extent, we just render the
                    // original extent from the image.
                    let task = try? ciContext.startTask(
                        toRender: image,
                        from: iRect,
                        to: destination,
                        at: CGPoint(x: shiftX, y: shiftY)
                    )
                    
#if DEBUG
                    if self.debugMode {
                        commandBuffer.addCompletedHandler { _ in
                            let info = try? task?.waitUntilCompleted()
                            LibLogger.default.log("Render task completed: \(String(describing: info))")
                        }
                    }
#endif
                    
                    // Insert a command to present the drawable when the buffer has been scheduled for execution.
                    commandBuffer.present(drawable)
                    
                    // Commit the command buffer so that the GPU executes the work that the Core Image Render Task issues.
                    commandBuffer.commit()
                }
                
                if let queue = queue {
                    queue.async {
                        block()
                    }
                } else {
                    block()
                }
            }
        }
    }
}
