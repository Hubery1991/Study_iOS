// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClavewellCore",
    products: [
        .library(name: "ClavewellCore", targets: ["ClavewellCore"])
    ],
    targets: [
        .target(
            name: "ClavewellCore",
            path: "Sources/ClavewellCore"
        ),
        .testTarget(
            name: "ClavewellCoreTests",
            dependencies: ["ClavewellCore"],
            path: "Tests/ClavewellCoreTests"
        )
    ]
)
