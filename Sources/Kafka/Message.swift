import Foundation

struct Message: Encodable, CustomKafkaSerializable {
    enum Version {
        case one
    }
    
    let key: Data
    let value: Data
    
    init(key: Data, value: Data) {
        self.key = key
        self.value = value
    }
    
    func size(version: Version = .one) -> Int32 {
        return numericCast(6 + self.key.count + self.value.count)
    }
    
    func serialize() -> Data {
        var header = [UInt8]()
        
        // magic
        header.append(1)
        
        // attributes
        header.append(0)
        
        // TODO: Timestamp for message version 1
        var keyLengthData = [UInt8](repeating: 0, count: 4)
        var keyLength = Int32(key.count).bigEndian
        memcpy(&keyLengthData, &keyLength, 4)
        
        var valueLengthData = [UInt8](repeating: 0, count: 4)
        var valueLength = Int32(value.count).bigEndian
        memcpy(&valueLengthData, &valueLength, 4)
        
        var message = Data(header + keyLengthData) + key + Data(valueLengthData) + value
        
        var crc = makeCRC32(message)
        var buffer = [UInt8](repeating: 0, count: 4)
        
        memcpy(&buffer, &crc, 4)
        
        message.insert(contentsOf: buffer, at: 0)
        
        return message
    }
}

struct MessageSetElement: Encodable {
    var offset: Int64
    var size: Int32
    var message: Message
    
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

typealias MessageSet = [MessageSetElement]
