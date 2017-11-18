import Async
import XCTest
import TCP
@testable import Kafka

class KafkaTests: XCTestCase {
    func testExample() throws {
        let socket = try Socket()
        try socket.connect(hostname: "localhost", port: 9092)
        let queue = DispatchQueue(label: "test")
        
        let client = try socket.writable(queue: queue).map { _ -> TCPClient in
            let client = TCPClient(socket: socket, worker: queue)
            client.start()
            return client
        }.blockingAwait(timeout: .seconds(3))
        
        let promise = Promise<Void>()
        
        client.drain { buffer in
            print(Array(buffer))
            promise.complete()
        }
        
        let produce = ProduceRequest(
            requiredAknowledgements: 1,
            timeoutMS: 1000,
            messages: [
                .init(topic: "hello", data: [
//                    .init(partition: 0, messages: [.init(offset: 0, message: .init(key: .init("key".utf8), value: .init("value".utf8)))])
                ])
            ]
        )
        
        let request = Request(apiKey: .produce, apiVersion: 0, correlationId: 1, clientId: "a12", message: produce)
        
        let message = try KafkaEncoder().encode(request)
        
        sleep(1)
        print(Array(message))
        
        client.inputStream(message)
        
        try promise.future.blockingAwait()
        
        client.close()
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
