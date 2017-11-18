struct RequestHeader: Encodable {
    var key: APIKey
    var version: Int16
    var correlationId: Int32
    var clientId: String
}

struct ResponseHeader: Encodable {
    enum CodingKeys: String, Codable, CodingKey {
        case correlationId = "correlation_id"
    }
    
    var correlationId: Int32
}
