import Async
import XCTest
import TCP
@testable import Kafka

class KafkaTests: XCTestCase {
    func testExample() throws {
        let client = try KafkaClient(hostname: "localhost", port: 9092)
        
        let produce = ProduceRequest(
            requiredAknowledgements: 1,
            timeoutMS: 1000,
            messages: [
                .init(topic: "hello", data: [
                    .init(partition: 0, messages: [.init(offset: 0, message: .init(key: "key", value: "value"))])
                ])
            ]
        )
        
        let request = Request(apiKey: .produce, apiVersion: 0, correlationId: 1, clientId: "a12", message: produce)
        
        print(try client.send(message: request, expecting: ProduceResponse.self))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
