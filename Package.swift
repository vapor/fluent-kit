// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "fluent-kit",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "FluentKit", targets: ["FluentKit"]),
        .library(name: "FluentBenchmark", targets: ["FluentBenchmark"]),
        .library(name: "FluentSQL", targets: ["FluentSQL"]),
        .library(name: "XCTFluent", targets: ["XCTFluent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0-rc.1"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0-rc.1"),
    ],
    targets: [
        .target(name: "FluentKit", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "AsyncKit", package: "async-kit"),
        ]),
        .target(name: "FluentBenchmark", dependencies: [
            .target(name: "FluentKit"),
            .target(name: "FluentSQL"),
            .product(name: "AsyncKit", package: "async-kit"),
        ]),
        .target(name: "FluentSQL", dependencies: [
            .target(name: "FluentKit"),
            .product(name: "SQLKit", package: "sql-kit"),
        ]),
        .target(name: "XCTFluent", dependencies: [
            .target(name: "FluentKit")
        ]),
        .testTarget(name: "FluentKitTests", dependencies: [
            .target(name: "FluentBenchmark"),
            .target(name: "FluentSQL"),
            .target(name: "XCTFluent")
        ]),
    ]
)
