// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotonMetalDisplayCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PhotonMetalDisplayCoreStatic",
            type: .static,
            targets: ["PhotonMetalDisplayCore"]
        ),
        .library(
            name: "PhotonMetalDisplayCoreDynamic",
            type: .dynamic,
            targets: ["PhotonMetalDisplayCore"]
        ),
        .library(
            name: "PhotonMetalDisplayCore",
            targets: ["PhotonMetalDisplayCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PhotonMetalDisplayCore"),
        .testTarget(
            name: "PhotonMetalDisplayCoreTests",
            dependencies: ["PhotonMetalDisplayCore"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
