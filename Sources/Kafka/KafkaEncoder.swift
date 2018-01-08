import Foundation

protocol CustomKafkaSerializable {
    func serialize() -> Data
}

final class KafkaEncoder {
    init() {}
    
    func encode<M>(_ request: Request<M>) throws -> Data {
        let encoder = RequestEncoder()
//        try headers.encode(to: encoder)
        try request.encode(to: encoder)
        encoder.updateSize()
        return encoder.data
    }
}

fileprivate final class RequestEncoder: Encoder {
    fileprivate var codingPath = [CodingKey]()
    
    fileprivate var userInfo = [CodingUserInfoKey : Any]()
    
    fileprivate var data = Data([0, 0, 0, 0])
    
    fileprivate init() {}
    
    fileprivate func updateSize() {
        let size = numericCast(data.count - 4) as Int32
        
        data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<Int32>) in
            pointer.pointee = size.bigEndian
        }
    }
    
    fileprivate func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KafkaKeyedEncodingContainer(encoder: self, codingPath: codingPath))
    }
    
    fileprivate func unkeyedContainer() -> UnkeyedEncodingContainer {
        return KafkaUnkeyedEncodingContainer(encoder: self, codingPath: codingPath)
    }
    
    fileprivate func singleValueContainer() -> SingleValueEncodingContainer {
        return KafkaSingleValueEncodingContainer(encoder: self, codingPath: codingPath)
    }
    
    fileprivate func encode(_ value: String) throws {
        let stringData = Data(value.utf8)
        
        guard stringData.count < numericCast(Int16.max) else {
            throw UnsupportedStringLength()
        }
        
        try encode(numericCast(stringData.count) as Int16)
        self.data.append(stringData)
    }
    
    fileprivate func encode(_ value: Int8) throws {
        self.data.append(numericCast(value))
    }
    
    fileprivate func encode(_ value: Int16) throws {
        var value = value.bigEndian
        
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            
            self.data.append(buffer, count: 2)
        }
    }
    
    fileprivate func encode(_ value: Int32) throws {
        var value = value.bigEndian
        
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            
            self.data.append(buffer, count: 4)
        }
    }
    
    fileprivate func encode(_ value: Int64) throws {
        var value = value.bigEndian
        
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            
            self.data.append(buffer, count: 8)
        }
    }
}

fileprivate struct KafkaSingleValueEncodingContainer: SingleValueEncodingContainer, SingleKafkaEncoder {
    var count: Int = 0
    
    fileprivate var codingPath: [CodingKey]
    fileprivate let encoder: RequestEncoder
    
    fileprivate mutating func encodeNil() throws {
        try self.encode(-1 as Int32)
    }
    
    fileprivate init(encoder: RequestEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
}

fileprivate struct KafkaKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol, SingleKafkaEncoder {
    mutating func encode(_ value: Int, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        try encode(value)
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        try encode(value)
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        throw UnsupportedKafkaType()
    }
    
    mutating func encodeNil(forKey key: K) throws {
        try self.encodeNil()
    }
    
    fileprivate mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(KafkaKeyedEncodingContainer<NestedKey>(encoder: encoder, codingPath: self.codingPath + [key]))
    }
    
    fileprivate mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return KafkaUnkeyedEncodingContainer(encoder: encoder, codingPath: codingPath + [key])
    }
    
    fileprivate mutating func superEncoder() -> Encoder {
        return encoder
    }
    
    fileprivate mutating func superEncoder(forKey key: K) -> Encoder {
        return encoder
    }
    
    fileprivate var count = 0
    fileprivate typealias Key = K
    
    fileprivate var codingPath: [CodingKey]
    fileprivate let encoder: RequestEncoder
    
    fileprivate init(encoder: RequestEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
}

fileprivate final class KafkaUnkeyedEncodingContainer: UnkeyedEncodingContainer, SingleKafkaEncoder {
    fileprivate var count = 1
    fileprivate let countIndex: Int
    
    fileprivate func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        count += 1
        
        return KeyedEncodingContainer(KafkaKeyedEncodingContainer(encoder: encoder, codingPath: codingPath))
    }
    
    fileprivate func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        count += 1
        
        return KafkaUnkeyedEncodingContainer(encoder: encoder, codingPath: codingPath)
    }
    
    fileprivate func superEncoder() -> Encoder {
        count += 1
        
        return encoder
    }
    
    fileprivate var codingPath: [CodingKey]
    fileprivate let encoder: RequestEncoder
    
    fileprivate init(encoder: RequestEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.countIndex = encoder.data.endIndex
        encoder.data.append(contentsOf: [0, 0, 0, 0])
    }
    
    deinit {
        encoder.data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
            pointer.advanced(by: self.countIndex).withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
                pointer.pointee = (numericCast(self.count) as Int32).bigEndian
            }
        }
    }
}

fileprivate protocol SingleKafkaEncoder {
    var encoder: RequestEncoder { get }
}

extension SingleKafkaEncoder {
    fileprivate mutating func encodeNil() throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: Int) throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: Int8) throws {
        encoder.data.append(numericCast(value))
    }
    
    fileprivate mutating func encode(_ value: Int16) throws {
        try encoder.encode(value)
    }
    
    fileprivate mutating func encode(_ value: Int32) throws {
        try encoder.encode(value)
    }
    
    fileprivate mutating func encode(_ value: Int64) throws {
        try encoder.encode(value)
    }
    
    fileprivate mutating func encode(_ value: UInt) throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: UInt8) throws {
        encoder.data.append(value)
    }
    
    fileprivate mutating func encode(_ value: UInt16) throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: UInt32) throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: UInt64) throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: Float) throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: Double) throws {
        throw UnsupportedKafkaType()
    }
    
    fileprivate mutating func encode(_ value: String) throws {
        try self.encoder.encode(value)
    }
    
    fileprivate mutating func encode<T>(_ value: T) throws where T : Encodable {
        if let value = value as? CustomKafkaSerializable {
            self.encoder.data.append(value.serialize())
        } else {
            try value.encode(to: encoder)
        }
    }
    
    fileprivate mutating func encode(_ value: Bool) throws {
        throw UnsupportedKafkaType()
    }
}

fileprivate struct UnsupportedKafkaType: Error {}
fileprivate struct UnsupportedStringLength: Error {}
