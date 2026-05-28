// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "IndustrialRouter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "IndustrialRouter",
            targets: ["IndustrialRouter"]
        )
    ],
    targets: [
        .target(
            name: "IndustrialRouter",
            path: "Sources/IndustrialRouter"
        )
    ],
    swiftLanguageVersions: [.v5]
)
