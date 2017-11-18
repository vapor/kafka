struct ProduceRequest: Encodable {
    struct Request: Encodable {
        struct Data: Encodable {
            var partition: Int32
            var messageSetBytes: Int32
            var messages: MessageSet
            
            init(partition: Int32, messages: MessageSet) {
                self.partition = partition
                self.messageSetBytes = messages.size
                self.messages = messages
            }
        }
        
        var topic: String
        var data: [Data]
    }
    
    var requiredAknowledgements: Int16
    var timeoutMS: Int32
    var messages: [Request]
}

struct ProduceResponse: Decodable {
    struct Response: Decodable {
        struct PartitionResponse: Decodable {
            var partition: Int32
            var errorCode: Int16
            var baseOffset: Int64
            var logAppendTime: Int64
            var logStartOffset: Int64
        }
        
        var topic: String
        var partitionResponses: [PartitionResponse]
    }
    
    var records: [Response]
    var throttleTimeMS: Int32
}
