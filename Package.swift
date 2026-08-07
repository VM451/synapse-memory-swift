// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mem0Swift",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
        .watchOS(.v10)
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
