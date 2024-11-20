# Enable HDR Rendering

``MetalView`` also supports render in HDR mode.

## Enable MetalView HDR Rendering

There is a parameter in ``MetalView`` named prefersDynamicRange of ``MetalDynamicRange`` type.

Set this to the target dynamic range you want to render and make sure that the CIImage you provide has the same dynamic range.

```swift
MetalView(
    renderer: viewModel.renderer,
    renderMode: .renderWhenDirty,
    prefersDynamicRange: MetalDynamicRange.hdr
)
```

The `prefersDynamicRange` parameter can be changed at runtime, for example, when the user switches between SDR and HDR mode.
                                                                    
When the parameter is changed, the underlying view will be configured to render in the new dynamic range.
                                                                    
## Get CIImage applied with Gain Map

Starting with iOS 18, there is an API to help you create a CIImage with a gain map applied:

First load the basic SDR image:

```swift
guard let url = Bundle.main.url(forResource: "test", withExtension: "jpg") else {
    return nil
}
guard let inputImage = CIImage(contentsOf: url) else {
    return nil
}
```

Then load the gain map image:

```swift
let gainMap = CIImage(contentsOf: url, options: [.auxiliaryHDRGainMap: true, .applyOrientationProperty: true])
```

Apply the gain map to the input image:

```swift
let appliedGainMapImage = inputImage.applyingGainMap(gainMap)
```

> Note: If you set the render mode to ``MetalRenderMode/renderWhenDirty``, you should call the ``MetalRenderer/requestChanged(displayedImage:)`` method to update the image.
