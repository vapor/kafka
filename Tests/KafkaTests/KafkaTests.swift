import XCTest
@testable import Kafka

class KafkaTests: XCTestCase {
    func testExample() throws {
        let producer = try KafkaClient(hostname: "localhost", port: 9092)
        let produce = try producer.produce([
            "": "value"
        ], toTopic: "hello", acknowledge: .one)
        print(produce)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
