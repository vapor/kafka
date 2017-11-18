// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kafka",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Kafka",
            targets: ["Kafka"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-alpha.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
//        .target(
//            name: "Bits",
//            dependencies: []),
//        .target(
//            name: "libc",
//            dependencies: []),
//        .target(
//            name: "Async",
//            dependencies: []),
//        .target(
//            name: "Debugging",
//            dependencies: []),
//        .target(
//            name: "TCP",
//            dependencies: ["Async", "Bits", "libc", "Debugging"]),
        .target(
            name: "Kafka",
            dependencies: ["TCP"]),
        .testTarget(
            name: "KafkaTests",
            dependencies: ["Kafka"]),
    ]
)
