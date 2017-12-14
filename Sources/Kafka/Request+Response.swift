public struct Request<M: Encodable>: Encodable {
    public var apiKey: APIKey
    public var apiVersion: Int16
    public var correlationId: Int32
    public var clientId: String
    public var message: M
}

public struct Response<M: Decodable>: Decodable {
    public var correlationId: Int32
    public var message: M
}
