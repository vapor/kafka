import Foundation

public struct Message: Encodable {
    enum Version {
        case one
    }
    
    var crc32: Int32
    let magic: UInt8 = 1
    var attributes: UInt8 = 0
    public let key: Bytes
    public let value: Bytes
    
    public init(key: Bytes, value: Bytes) {
        self.crc32 = 0
        self.key = key
        self.value = value
        
        self.crc32 = generateCRC32()
    }
    
    func size(version: Version = .one) -> Int32 {
        return numericCast(6 + self.key.size + self.value.size)
    }
    
    func generateCRC32() -> Int32 {
        var header = [UInt8]()

        // magic
        header.append(magic)

        // attributes
        header.append(attributes)

        // TODO: Timestamp for message version 1
        var keyLengthData = [UInt8](repeating: 0, count: 4)
        var keyLength = Int32(key.count).bigEndian
        memcpy(&keyLengthData, &keyLength, 4)

        var valueLengthData = [UInt8](repeating: 0, count: 4)
        var valueLength = Int32(value.count).bigEndian
        memcpy(&valueLengthData, &valueLength, 4)

        let message = Data(header + keyLengthData) + key.data + Data(valueLengthData) + value.data

        return Int32(bitPattern: makeCRC32(message))
    }
}

public struct MessageSetElement: Encodable {
    var offset: Int64
    var size: Int32
    public var message: Message
    
    init(offset: Int64, message: Message) {
        self.offset = offset
        self.size = message.size()
        self.message = message
    }
}

extension Array where Element == MessageSetElement {
    var size: Int32 {
        var count: Int32 = 0
        
        for element in self {
            // header
            count += 12
            
            // message
            count += element.message.size()
        }
        
        return count
    }
}

typealias _MessageSet = [MessageSetElement]

public struct MessageSet: Encodable, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    var messages: _MessageSet
    
    public func encode(to encoder: Encoder) throws {
        try messages.encode(to: encoder)
    }
    
    public init(arrayLiteral elements: MessageSetElement...) {
        self.messages = elements
    }
    
    public init(dictionaryLiteral elements: (Bytes, Bytes)...) {
        self.messages = elements.map { key, value in
            return MessageSetElement(offset: 0, message: Message(key: key, value: value))
        }
    }
}
