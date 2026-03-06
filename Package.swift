// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ObjectArchiveKit",
    products: [
        .library(
            name: "ObjectArchiveKit",
            targets: ["ObjectArchiveKit"]
        ),
    ],
    targets: [
        .target(
            name: "ObjectArchiveKit"
        ),
        .testTarget(
            name: "ObjectArchiveKitTests",
            dependencies: ["ObjectArchiveKit"]
        ),
    ]
)
