// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Kafka",
    products: [
        .library(name: "Kafka", targets: ["Kafka"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/sockets.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "Kafka", dependencies: ["Sockets", "Transport"]),
        .testTarget(name: "KafkaTests", dependencies: ["Kafka"]),
    ]
)
