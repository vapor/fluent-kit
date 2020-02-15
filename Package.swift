// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "fluent-kit",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "FluentKit", targets: ["FluentKit"]),
        .library(name: "FluentBenchmark", targets: ["FluentBenchmark"]),
        .library(name: "FluentSQL", targets: ["FluentSQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0-beta.6.1"),
    ],
    targets: [
        .target(name: "FluentKit", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "Logging", package: "swift-log"),
        ]),
        .target(name: "FluentBenchmark", dependencies: [
            .target(name: "FluentKit"),
            .target(name: "FluentSQL"),
        ]),
        .target(name: "FluentSQL", dependencies: [
            .target(name: "FluentKit"),
            .product(name: "SQLKit", package: "sql-kit"),
        ]),
        .testTarget(name: "FluentKitTests", dependencies: [
            .target(name: "FluentBenchmark"),
            .target(name: "FluentSQL"),
        ]),
    ]
)
