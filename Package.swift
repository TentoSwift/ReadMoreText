// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReadMoreText",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [.library(name: "ReadMoreText", targets: ["ReadMoreText"])],
    targets: [
        .target(name: "ReadMoreText", resources: [.process("Resources")]),
        .testTarget(name: "ReadMoreTextTests", dependencies: ["ReadMoreText"])
    ]
)
