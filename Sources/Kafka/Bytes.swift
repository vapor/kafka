import Foundation

public enum Bytes: ExpressibleByNilLiteral, ExpressibleByStringLiteral, ExpressibleByArrayLiteral, CustomKafkaSerializable, Encodable {
    case null
    case data(Data)
    
    public init(stringLiteral value: String) {
        self = .data(Data(value.utf8))
    }
    
    public init(nilLiteral: ()) {
        self = .null
    }
    
    public init(arrayLiteral elements: UInt8...) {
        self = .data(Data(elements))
    }
    
    public init(data: Data) {
        self = .data(data)
    }
    
    func serialize() -> Data {
        switch self {
        case .null:
            return Data([255, 255, 255, 255]) // -1
        case .data(let data):
            var value = Int32(data.count).bigEndian
            
            return withUnsafeBytes(of: &value) { buffer in
                return Data(buffer) + data
            }
        }
    }
    
    var data: Data {
        switch self {
        case .null: return Data()
        case .data(let data): return data
        }
    }
    
    var count: Int {
        switch self {
        case .null: return -1
        case .data(let data): return data.count
        }
    }
    
    var size: Int {
        switch self {
        case .null: return 4
        case .data(let data): return 4 + data.count
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        throw Unsupported()
    }
}

fileprivate struct Unsupported: Error {}
