// swift-tools-version: 5.10

import PackageDescription

let binaryParseSupportVersion: Version = "0.2.1"

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
        )
    ],
    targets: [
        .target(
            name: "ObjectArchiveKit",
            dependencies: [
                "ObjectArchiveKitC",
                .product(name: "FileIO", package: "swift-fileio"),
                .product(name: "FileIOBinary", package: "swift-fileio-extra")
            ]
        ),
        .target(name: "ObjectArchiveKitC"),
        .testTarget(
            name: "ObjectArchiveKitTests",
            dependencies: ["ObjectArchiveKit"]
        ),
    ]
)

// MARK: - Binary Parse Support

let objectArchiveKit = package.targets
    .first(where: { $0.name == "ObjectArchiveKit" })

let isForBinaryKitFramework = Context.environment["BUILD_BINARY_KIT_FW"] != nil

if isForBinaryKitFramework {
    package.dependencies += [
        .package(
            url: "https://github.com/p-x9/swift-binary-parse-support-bin.git",
            from: binaryParseSupportVersion
        ),
    ]
    objectArchiveKit?.dependencies += [
        .product(
            name: "BinaryParseSupport",
            package: "swift-binary-parse-support-bin"
        )
    ]
} else {
    package.dependencies += [
        .package(
            url: "https://github.com/p-x9/swift-binary-parse-support.git",
            from: binaryParseSupportVersion
        ),
    ]
    objectArchiveKit?.dependencies += [
        .product(
            name: "BinaryParseSupport",
            package: "swift-binary-parse-support"
        )
    ]
}
