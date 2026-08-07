// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mem0Swift",
    platforms: [
        .iOS("27.0"),
        .macOS("27.0"),
        .visionOS("27.0"),
        .watchOS("20.0")
    ],
    products: [
        .library(
            name: "Mem0Swift",
            targets: ["Mem0Swift"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.3")
    ],
    targets: [
        .target(
            name: "Mem0Swift",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            exclude: [
                "Documentation.docc"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "Mem0SwiftTests",
            dependencies: ["Mem0Swift"]
        ),
    ]
)
