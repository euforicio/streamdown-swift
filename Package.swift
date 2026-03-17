// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Streamdown",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "Streamdown", targets: ["Streamdown"]),
        .library(name: "StreamdownUI", targets: ["StreamdownUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
    ],
    targets: [
        .target(name: "Streamdown"),
        .target(
            name: "StreamdownUI",
            dependencies: [
                "Streamdown",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]
        ),
        .testTarget(
            name: "StreamdownTests",
            dependencies: ["Streamdown"]
        ),
    ]
)
