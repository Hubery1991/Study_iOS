// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Mallowcrate",
    products: [
        .library(name: "MallowcrateCore", targets: ["MallowcrateCore"])
    ],
    targets: [
        .target(name: "MallowcrateCore"),
        .testTarget(
            name: "MallowcrateCoreTests",
            dependencies: ["MallowcrateCore"]
        ),
    ]
)
