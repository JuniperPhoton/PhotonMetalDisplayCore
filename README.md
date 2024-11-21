# PhotonMetalDisplayCore

A simple Swift Package to help you render CIImage from Core Image in a MTKView in SwiftUI, supporting some other features like HDR rendering.

The generated documentation can be accessed via:

https://juniperphoton.github.io/PhotonMetalDisplayCore/documentation/photonmetaldisplaycore

## Generate the Swift DocC

### Using Swift DocC plugin:

```
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target PhotonMetalDisplayCore \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path PhotonMetalDisplayCore \
    --output-path './docs'
```

### Using Xcode build

```
xcodebuild docbuild -scheme PhotonMetalDisplayCore -derivedDataPath ~/Desktop/PhotonMetalDisplayCore -destination 'generic/platform=iOS' DOCC_HOSTING_BASE_PATH='PhotonMetalDisplayCore'
```

## Preview the documentation locally

```
swift package --disable-sandbox preview-documentation --target PhotonMediaDisplayCore
```
