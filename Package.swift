// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "fluent-kit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "FluentKit", targets: ["FluentKit"]),
        .library(name: "FluentBenchmark", targets: ["FluentBenchmark"]),
        .library(name: "FluentSQL", targets: ["FluentSQL"]),
        .library(name: "XCTFluent", targets: ["XCTFluent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.29.3"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.20.0"),
    ],
    targets: [
        .target(
            name: "FluentKit",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncKit", package: "async-kit"),
                .product(name: "SQLKit", package: "sql-kit"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FluentBenchmark",
            dependencies: [
                .target(name: "FluentKit"),
                .target(name: "FluentSQL"),
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "SQLKitBenchmark", package: "sql-kit"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FluentSQL",
            dependencies: [
                .product(name: "SQLKit", package: "sql-kit"),
                .target(name: "FluentKit"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "XCTFluent",
            dependencies: [
                .product(name: "NIOEmbedded", package: "swift-nio"),
                .target(name: "FluentKit"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FluentKitTests",
            dependencies: [
                .target(name: "FluentBenchmark"),
                .target(name: "FluentSQL"),
                .target(name: "XCTFluent"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
] }
