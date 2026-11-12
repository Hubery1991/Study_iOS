// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Nimvelle",
    products: [
        .library(name: "NimvelleCore", targets: ["NimvelleCore"])
    ],
    targets: [
        .target(name: "NimvelleCore"),
        .testTarget(
            name: "NimvelleCoreTests",
            dependencies: ["NimvelleCore"]
        ),
    ]
)
