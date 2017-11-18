struct Request<M: Encodable>: Encodable {
    var apiKey: APIKey
    var apiVersion: Int16
    var correlationId: Int32
    var clientId: String
    var message: M
}

struct Response<M: Decodable>: Decodable {
    var correlationId: Int32
    var message: M
}
