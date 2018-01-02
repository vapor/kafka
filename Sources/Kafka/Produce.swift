public enum RequiredAcknowledgements: Int16, Codable {
    case all = -1
    case none = 0
    case one = 1
}

struct ProduceRequest: Encodable {
    struct Request: Encodable {
        struct Data: Encodable {
            var partition: Int32
            var messageSetBytes: Int32
            var messages: MessageSet
            
            init(partition: Int32, messages messageSet: MessageSet) {
                self.partition = partition
                self.messageSetBytes = messageSet.messages.size
                self.messages = messageSet
            }
        }
        
        var topic: String
        var data: [Data]
    }
    
    var requiredAknowledgements: RequiredAcknowledgements
    var timeoutMS: Int32
    var messages: [Request]
}

public struct ProduceResponse: Decodable {
    public struct Response: Decodable {
        public struct PartitionResponse: Decodable {
            public var partition: Int32
            public var errorCode: Int16
            public var offset: Int64
        }
        
        public var topic: String
        public var partitionResponses: [PartitionResponse]
    }
    
    public var records: [Response]
}

extension KafkaClient {
    public func produce(_ messages: MessageSet, toTopic topic: String, acknowledge: RequiredAcknowledgements) throws -> Response<ProduceResponse> {
        // Produce can have any offset, it's generated on the server
        let produce = ProduceRequest(
            requiredAknowledgements: acknowledge,
            timeoutMS: settings.timeoutMS,
            messages: [
                ProduceRequest.Request(
                    topic: topic,
                    data: [
                        ProduceRequest.Request.Data(partition: 0, messages: messages)
                    ]
                )
            ]
        )
        
        let request = Request(
            apiKey: .produce,
            apiVersion: 0,
            correlationId: self.nextCorrelation,
            clientId: "VaporKafka",
            message: produce
        )
        
        return try self.send(message: request, expecting: ProduceResponse.self)
    }
}
