import Foundation
import Dispatch
import Sockets

public final class KafkaClient {
    public struct Settings {
        public var timeoutMS: Int32
    }
    
    var _nextCorrelation: Int32 = 0
    
    var nextCorrelation: Int32 {
        // Require overflow for potentially huge amounts of data (max 2 billion)
        defer { _nextCorrelation = _nextCorrelation &+ 1 }
        
        return _nextCorrelation
    }
    
    let client: TCPInternetSocket
    var data = Data()
    
    public var settings = Settings(timeoutMS: 500)
    
    public init(hostname: String, port: UInt16) throws {
        let socket = try TCPInternetSocket(scheme: "http", hostname: hostname, port: port)
        try socket.connect()
        client = socket
    }
    
    func send<M, R>(message: Request<M>, expecting: R.Type) throws -> Response<R> {
        var message = try KafkaEncoder().encode(message)
        print(message)
        print(message.makeBytes())
        print(String(data: message, encoding: .ascii)!)
        
        var written: Int
        
        repeat {
            written = try client.write(message)
            
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
        let read = try client.read(max: 65_535)
        self.data.append(Data(bytes: read))
        print(self.data)
        
        let decoder = KafkaDecoder()
        let decoded = try decoder.decode(R.self, from: self.data)
        self.data.removeFirst(decoder.read)
        
        return decoded
    }
}

struct WriteError: Error {}
