import NIO

public final class DummyDatabase: DatabaseDriver {
    public let eventLoopGroup: EventLoopGroup
    var didShutdown: Bool
    
    public var fieldDecoder: Decoder {
        return DummyDecoder()
    }

    public init(on eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.didShutdown = false
    }

    public func execute(
        query: DatabaseQuery,
        database: Database,
        onRow: @escaping (DatabaseRow) -> ()
    ) -> EventLoopFuture<Void> {
        for _ in 0..<Int.random(in: 1..<42) {
            onRow(DummyRow())
        }
        return database.eventLoop.makeSucceededFuture(())
    }
    
    public func execute(
        schema: DatabaseSchema,
        database: Database
    ) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    
    public func shutdown() {
        self.didShutdown = true
    }
    
    public func withConnection<T>(
        database: Database,
        _ closure: @escaping (DatabaseDriver) -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        return closure(self)
    }

    deinit {
        assert(self.didShutdown, "DummyDatabase did not shutdown before deinit.")
    }
}

// MARK: Private

private struct DummyRow: DatabaseRow {
    func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T
        where T: Decodable
    {
        return try T(from: DummyDecoder())
    }

    func contains(field: String) -> Bool {
        return true
    }
    
    var description: String {
        return "<dummy>"
    }
}

private struct DummyDecoder: Decoder {
    var codingPath: [CodingKey] {
        return []
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        return [:]
    }
    
    init() {
        
    }
    
    struct KeyedDecoder<Key>: KeyedDecodingContainerProtocol
        where Key: CodingKey
    {
        var codingPath: [CodingKey] {
            return []
        }
        var allKeys: [Key] {
            return [
                Key(stringValue: "test")!
            ]
        }
        
        init() { }
        
        func contains(_ key: Key) -> Bool {
            return false
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            return false
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            return try T.init(from: DummyDecoder())
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return KeyedDecodingContainer<NestedKey>(KeyedDecoder<NestedKey>())
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return UnkeyedDecoder()
        }
        
        func superDecoder() throws -> Decoder {
            return DummyDecoder()
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            return DummyDecoder()
        }
    }
    
    struct UnkeyedDecoder: UnkeyedDecodingContainer {
        var codingPath: [CodingKey]
        var count: Int?
        var isAtEnd: Bool {
            guard let count = self.count else {
                return true
            }
            return self.currentIndex >= count
        }
        var currentIndex: Int
        
        init() {
            self.codingPath = []
            self.count = 1
            self.currentIndex = 0
        }
        
        mutating func decodeNil() throws -> Bool {
            return true
        }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try T.init(from: DummyDecoder())
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return KeyedDecodingContainer<NestedKey>(KeyedDecoder())
        }
        
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return UnkeyedDecoder()
        }
        
        mutating func superDecoder() throws -> Decoder {
            return DummyDecoder()
        }
    }
    
    struct SingleValueDecoder: SingleValueDecodingContainer {
        var codingPath: [CodingKey] {
            return []
        }
        
        init() { }
        
        func decodeNil() -> Bool {
            return false
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            return false
        }
        
        func decode(_ type: String.Type) throws -> String {
            return "foo"
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            return 3.14
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            return 1.59
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            return -42
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            return -8
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            return -16
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            return -32
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            return -64
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            return 42
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            return 8
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            return 16
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            return 32
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            return 64
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try T(from: DummyDecoder())
        }
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return .init(KeyedDecoder())
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedDecoder()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueDecoder()
    }
}
