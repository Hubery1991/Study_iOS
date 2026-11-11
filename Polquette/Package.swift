// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Polquette",
    products: [
        .library(name: "PolquetteCore", targets: ["PolquetteCore"])
    ],
    targets: [
        .target(name: "PolquetteCore"),
        .testTarget(
            name: "PolquetteCoreTests",
            dependencies: ["PolquetteCore"]
        ),
    ]
)
