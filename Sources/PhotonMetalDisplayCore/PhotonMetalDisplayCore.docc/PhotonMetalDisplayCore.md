# ``PhotonMetalDisplayCore``

A simple Swift Package to help you render CIImage from Core Image in a MTKView in SwiftUI, supporting some other features like HDR rendering.

## Installation

### For App

In Xcode, navigate to the root Project settings > `Package Dependencies` and add the following URL of this repository:

```
https://github.com/JuniperPhoton/PhotonMetalDisplayCore
```

### For Swift Package

Add the following line to the dependencies in your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/JuniperPhoton/PhotonMetalDisplayCore", from: "1.0.1")
],
```

## Sample Project

You can navigate to the `./Demo` folder to see the sample project.

## Topics

### Essential

- <doc:RenderEssential>
- <doc:EnableHDRRender>

### Rendering

- ``MetalView``
- ``MetalRenderer``

### Observe HDR Content Display

- ``HDRContentDisplayObserver``
