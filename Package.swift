// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "fluent-kit",
    products: [
        .library(name: "FluentKit", targets: ["FluentKit"]),
        .library(name: "FluentBenchmark", targets: ["FluentBenchmark"]),
        .library(name: "FluentSQL", targets: ["FluentSQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0-convergence"),
        .package(url: "https://github.com/vapor/sql.git", .branch("master")),
        .package(url: "https://github.com/vapor/codable-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "FluentKit", dependencies: ["CodableKit", "NIO"]),
        .target(name: "FluentBenchmark", dependencies: ["FluentKit"]),
        .target(name: "FluentSQL", dependencies: ["FluentKit", "SQLKit"]),
        .testTarget(name: "FluentKitTests", dependencies: ["FluentBenchmark"]),
    ]
)
