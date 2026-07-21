// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "adaptive_network_policy",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15")
    ],
    products: [
        .library(name: "adaptive-network-policy", targets: ["adaptive_network_policy"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "adaptive_network_policy",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: []
        ),
        .testTarget(
            name: "adaptive_network_policyTests",
            dependencies: ["adaptive_network_policy"]
        )
    ]
)
