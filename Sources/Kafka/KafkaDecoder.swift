import Foundation

final class KafkaDecoder {
    init() {}
    
    var read = 0
    
    func decode<M>(_ response: M.Type, from data: Data) throws -> Response<M> {
        let decoder = try ResponseDecoder(data: data)
        let decoded = try Response<M>(from: decoder)
        read = numericCast(decoder.read)
        return decoded
    }
}

fileprivate final class ResponseDecoder: Decoder {
    fileprivate var codingPath = [CodingKey]()
    
    fileprivate var userInfo = [CodingUserInfoKey : Any]()
    
    fileprivate var data: Data
    fileprivate var read: Int32 = 0
    fileprivate var position = 0
    
    fileprivate init(data: Data) throws {
        self.data = data
        self.read = try self.decode()
    }
    
    fileprivate func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KafkaKeyedDecodingContainer(decoder: self))
    }
    
    fileprivate func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try KafkaUnkeyedDecodingContainer(decoder: self)
    }
    
    fileprivate func singleValueContainer() throws -> SingleValueDecodingContainer {
        return KafkaSingleValueDecodingContainer(decoder: self)
    }
    
    fileprivate func remaining(_ n: Int) throws {
        guard data.count - position >= n else {
            print(2)
            throw InvalidResponseFormat()
        }
    }
    
    fileprivate func decode() throws -> Int8 {
        try remaining(1)
        
        defer { position += 1 }
        
        return numericCast(data[position])
    }
    
    fileprivate func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try T(from: self)
    }
    
    fileprivate func decode() throws -> Int16 {
        try remaining(2)
        
        defer { position += 2 }
        
        return data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            return pointer.advanced(by: position).withMemoryRebound(to: Int16.self, capacity: 1) { pointer in
                return pointer.pointee.bigEndian
            }
        }
    }
    
    fileprivate func decode() throws -> Int32 {
        try remaining(4)
        
        defer { position += 4 }
        
        return data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            return pointer.advanced(by: position).withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
                return pointer.pointee.bigEndian
            }
        }
    }
    
    fileprivate func decode() throws -> Int64 {
        try remaining(8)
        
        defer { position += 8 }
        
        return data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            return pointer.advanced(by: position).withMemoryRebound(to: Int64.self, capacity: 1) { pointer in
                return pointer.pointee.bigEndian
            }
        }
    }
    
    fileprivate func decode() throws -> String {
        let size: Int16 = try decode()
        
        try remaining(numericCast(size))
        
        defer { position += numericCast(size) }
        
        guard let string = String(data: data[position..<position + numericCast(size)], encoding: .utf8) else {
            print(1)
            throw InvalidResponseFormat()
        }
        
        return string
    }
}

fileprivate struct KafkaKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var allKeys = [K]()
    
    func contains(_ key: K) -> Bool {
        return true
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try decoder.decode()
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try decoder.decode()
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try decoder.decode()
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try decoder.decode()
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try decoder.decode()
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        return try decoder.decode(T.self)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedDecodingContainer(KafkaKeyedDecodingContainer<NestedKey>(decoder: decoder))
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return try KafkaUnkeyedDecodingContainer(decoder: decoder)
    }
    
    func superDecoder() throws -> Decoder {
        return decoder
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        return decoder
    }
    
    typealias Key = K
    
    var codingPath: [CodingKey]
    
    fileprivate let decoder: ResponseDecoder
    
    fileprivate init(decoder: ResponseDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }
}

fileprivate struct KafkaUnkeyedDecodingContainer: UnkeyedDecodingContainer, DecodingHelper {
    var count: Int?
    
    var isAtEnd: Bool {
        return currentIndex >= count ?? 0
    }
    
    var currentIndex: Int = 0
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        currentIndex += 1
        return KeyedDecodingContainer(KafkaKeyedDecodingContainer(decoder: decoder))
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        currentIndex += 1
        return try KafkaUnkeyedDecodingContainer(decoder: decoder)
    }
    
    mutating func superDecoder() throws -> Decoder {
        currentIndex += 1
        return decoder
    }
    
    var codingPath: [CodingKey]
    
    fileprivate let decoder: ResponseDecoder
    
    fileprivate init(decoder: ResponseDecoder) throws {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        
        self.count = numericCast(try decoder.decode() as Int32)
        
    }
}

fileprivate struct KafkaSingleValueDecodingContainer: SingleValueDecodingContainer, DecodingHelper {
    var codingPath: [CodingKey]
    
    fileprivate let decoder: ResponseDecoder
    
    fileprivate init(decoder: ResponseDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }
}

fileprivate protocol DecodingHelper {
    var codingPath: [CodingKey] { get }
    var decoder: ResponseDecoder { get }
}

extension DecodingHelper {
    func decodeNil() -> Bool {
        return false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try decoder.decode()
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try decoder.decode()
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try decoder.decode()
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try decoder.decode()
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        throw UnsupportedKafkaType()
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try decoder.decode()
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try decoder.decode(T.self)
    }
}

fileprivate struct UnsupportedKafkaType: Error {}
fileprivate struct InvalidResponseFormat: Error {}
