// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "fluent-kit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(name: "FluentKit", targets: ["FluentKit"]),
        .library(name: "FluentBenchmark", targets: ["FluentBenchmark"]),
        .library(name: "FluentSQL", targets: ["FluentSQL"]),
        .library(name: "SQLKit", targets: ["SQLKit"]),
        .library(name: "SQLKitBenchmark", targets: ["SQLKitBenchmark"]),
        .library(name: "XCTFluent", targets: ["XCTFluent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.81.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.20.0"),
    ],
    targets: [
        .target(
            name: "FluentKit",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncKit", package: "async-kit"),
                .target(name: "SQLKit"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SQLKit",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncKit", package: "async-kit"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FluentBenchmark",
            dependencies: [
                .target(name: "FluentKit"),
                .target(name: "FluentSQL"),
                .target(name: "SQLKit"),
                .target(name: "SQLKitBenchmark"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SQLKitBenchmark",
            dependencies: [
                .target(name: "SQLKit"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FluentSQL",
            dependencies: [
                .target(name: "SQLKit"),
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
        .testTarget(
            name: "SQLKitTests",
            dependencies: [
                .target(name: "SQLKitBenchmark"),
                .target(name: "SQLKit"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
] }
