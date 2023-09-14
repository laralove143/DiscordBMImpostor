// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "DiscordBMImpostor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "DiscordBMImpostor",
            targets: ["DiscordBMImpostor"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/DiscordBM/DiscordBM", from: "1.0.0"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.1.0"),
        .package(url: "https://github.com/swiftpackages/DotEnv.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "DiscordBMImpostor",
            dependencies: [
                .product(name: "DiscordBM", package: "DiscordBM"),
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
        .testTarget(
            name: "DiscordBMImpostorTests",
            dependencies: ["DiscordBMImpostor", "DotEnv"],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
    ]
)
