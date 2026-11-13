// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Lookmira",
    products: [
        .library(name: "LookmiraCore", targets: ["LookmiraCore"])
    ],
    targets: [
        .target(name: "LookmiraCore"),
        .testTarget(
            name: "LookmiraCoreTests",
            dependencies: ["LookmiraCore"]
        )
    ]
)
