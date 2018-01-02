import Async
import XCTest
import TCP
@testable import Kafka

class KafkaTests: XCTestCase {
    func testExample() throws {
        let producer = try KafkaClient(hostname: "localhost", port: 9092)
        let consumer = try KafkaClient(hostname: "localhost", port: 9092)
        
        consumer.consume
        
        let produce = try producer.produce([
            "key": "value"
        ], toTopic: "hello", acknowledge: .one)
        
        XCTAssertEqual(produce.message.records.count, 1)
        
        _ = consumer
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
