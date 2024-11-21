# ``PhotonMetalDisplayCore``

A simple Swift Package to help you render CIImage from Core Image in a MTKView in SwiftUI, supporting some other features like HDR rendering.

@Metadata {
    @PageImage(purpose: icon, source: "metal-icon")
}

## Installation

### For App

In Xcode, navigate to the root `Project settings` > `Package Dependencies` and add the following URL of this repository:

```
https://github.com/JuniperPhoton/PhotonMetalDisplayCore
```

### For Swift Package

Add the following line to the dependencies in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/JuniperPhoton/PhotonMetalDisplayCore", from: "1.0.1")
],
```

## Essentials

@Links(visualStyle: list) {
    - <doc:RenderEssential>
    - <doc:EnableHDRRender>
    - <doc:SampleCode>
}

## Topics

### Rendering

- ``MetalView``
- ``MetalRenderer``

### Observe HDR Content Display

- ``HDRContentDisplayObserver``
