// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Vermessa",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "VermessaCore", targets: ["VermessaCore"])
    ],
    targets: [
        .target(
            name: "VermessaCore",
            path: "Sources/VermessaCore"
        ),
        .testTarget(
            name: "VermessaCoreTests",
            dependencies: ["VermessaCore"],
            path: "Tests/VermessaCoreTests"
        )
    ]
)
