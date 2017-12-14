import TCP
import Foundation
import Dispatch

public final class KafkaClient {
    let client: TCPClient
    var data = Data()
    
    public init(hostname: String, port: UInt16) throws {
        let socket = try TCPSocket(isNonBlocking: false)
        self.client = try TCPClient(socket: socket)
        try client.connect(hostname: hostname, port: port)
    }
    
    func send<M, R>(message: Request<M>, expecting: R.Type) throws -> Response<R> {
        var message = try KafkaEncoder().encode(message)
        
        var written: Int
        
        repeat {
            written = try client.socket.write(message)
            
            if written == message.count {
                return try readResponse(R.self)
            }
            
            guard written < message.count else {
                throw WriteError()
            }
            
            message.removeFirst(written)
        } while message.count > 0
        
        return try readResponse(R.self)
    }
    
    func readResponse<R>(_ type: R.Type) throws -> Response<R> {
        self.data.append(try client.socket.read(max: 65_535))
        
        let decoder = KafkaDecoder()
        let decoded = try decoder.decode(R.self, from: self.data)
        self.data.removeFirst(decoder.read)
        
        return decoded
    }
}

struct WriteError: Error {}
