// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fluent-kit",
    products: [
        .library(name: "FluentKit", targets: ["FluentKit"]),
        .library(name: "FluentBenchmark", targets: ["FluentBenchmark"]),
        .library(name: "FluentSQL", targets: ["FluentSQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        // .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0-beta"),
        .package(url: "https://github.com/mattpolzin/sql-kit.git", .revision("f6e96c9fd5efd82226aa17fb25e8015abe42c2e2")),
    ],
    targets: [
        .target(name: "FluentKit", dependencies: ["NIO", "Logging"]),
        .target(name: "FluentBenchmark", dependencies: ["FluentKit"]),
        .target(name: "FluentSQL", dependencies: ["FluentKit", "SQLKit"]),
        .testTarget(name: "FluentKitTests", dependencies: ["FluentBenchmark", "FluentSQL"]),
    ]
)
