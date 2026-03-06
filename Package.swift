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
    dependencies: [
        .package(
            url: "https://github.com/p-x9/swift-fileio.git",
            from: "0.13.0"
        ),
        .package(
            url: "https://github.com/p-x9/swift-fileio-extra.git",
            from: "0.2.2"
        ),
        .package(
            url: "https://github.com/p-x9/swift-binary-parse-support.git",
            from: "0.2.1"
        ),
    ],
    targets: [
        .target(
            name: "ObjectArchiveKit",
            dependencies: [
                "ObjectArchiveKitC",
                .product(name: "FileIO", package: "swift-fileio"),
                .product(name: "FileIOBinary", package: "swift-fileio-extra"),
                .product(
                    name: "BinaryParseSupport",
                    package: "swift-binary-parse-support"
                )
            ]
        ),
        .target(name: "ObjectArchiveKitC"),
        .testTarget(
            name: "ObjectArchiveKitTests",
            dependencies: ["ObjectArchiveKit"]
        ),
    ]
)
