// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sheenlisse",
    products: [
        .library(name: "SheenlisseCore", targets: ["SheenlisseCore"])
    ],
    targets: [
        .target(name: "SheenlisseCore"),
        .testTarget(
            name: "SheenlisseCoreTests",
            dependencies: ["SheenlisseCore"]
        ),
    ]
)
