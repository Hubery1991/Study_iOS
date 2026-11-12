// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Quillisse",
    products: [
        .library(name: "QuillisseCore", targets: ["QuillisseCore"])
    ],
    targets: [
        .target(name: "QuillisseCore"),
        .testTarget(
            name: "QuillisseCoreTests",
            dependencies: ["QuillisseCore"]
        ),
    ]
)
