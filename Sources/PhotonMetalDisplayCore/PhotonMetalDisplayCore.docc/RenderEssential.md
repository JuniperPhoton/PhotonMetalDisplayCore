# Use MetalView and MetalRenderer to render a CIImage

MetalView is a wrapper of MTKView, which provides a simple way to render Metal content in SwiftUI.

To construct a ``MetalView``, you need to provide a ``MetalRenderer`` object, which provides the CIImage to render.

First, construct the ``MetalRenderer`` object and initialize its CIContext:

```swift
let renderer = MetalRenderer()
renderer.initializeCIContext(colorSpace: nil, name: "my_renderer")
```

> Note: ``MetalRenderer/initializeCIContext(colorSpace:name:queue:)`` takes time to run, and you can do it off the main thread.

Then, construct the ``MetalView`` view:

```swift
MetalView(
    renderer: renderer,
    renderMode: .renderWhenDirty
)
```
Asides from ``MetalRenderer``, you should also provide a ``MetalRenderMode`` parameter to specify when the view should render the content.

There are two modes available:
- ``MetalRenderMode/continuous(fps:)``: Render the content every frame.
- ``MetalRenderMode/renderWhenDirty``: Render the content only when the content is dirty.

If you set the render mode to ``MetalRenderMode/renderWhenDirty``, you can call the ``MetalRenderer/requestChanged(displayedImage:)`` method to update the image.

And that's it! You can now construct a `CIImage` and set it to the renderer via ``MetalRenderer/requestChanged(displayedImage:)`` to render the content.

## Update image

When the underlying `CIImage` is changed, you must call ``MetalRenderer/requestChanged(displayedImage:)`` to update the image.
