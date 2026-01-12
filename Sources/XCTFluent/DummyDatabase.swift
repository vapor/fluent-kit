import FluentKit
import Foundation
import NIOEmbedded
import NIOCore
import NIOConcurrencyHelpers

public struct DummyDatabase: Database {
    public var context: DatabaseContext
    
    public init(context: DatabaseContext? = nil) {
        self.context = context ?? .init(
            configuration: DummyDatabaseConfiguration(middleware: []),
            logger: .init(label: "codes.vapor.test"),
            eventLoop: NIOAsyncTestingEventLoop()
        )
    }

    public var inTransaction: Bool {
        false
    }
    
    public func execute(query: DatabaseQuery, onOutput: @escaping @Sendable (any DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        for _ in 0..<Int.random(in: 1..<42) {
            onOutput(DummyRow())
        }
        return self.eventLoop.makeSucceededFuture(())
    }

    public func transaction<T>(_ closure: @escaping @Sendable(any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }
    
    public func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }
    
    public func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }

    public func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }
}

public struct DummyDatabaseConfiguration: DatabaseConfiguration {
    public var middleware: [any AnyModelMiddleware]

    public func makeDriver(for databases: Databases) -> any DatabaseDriver {
        DummyDatabaseDriver(on: databases.eventLoopGroup)
    }
}

public final class DummyDatabaseDriver: DatabaseDriver {
    public let eventLoopGroup: any EventLoopGroup
    let didShutdown: NIOLockedValueBox<Bool>
    
    public var fieldDecoder: any Decoder {
        DummyDecoder()
    }

    public init(on eventLoopGroup: any EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.didShutdown = .init(false)
    }
    
    public func makeDatabase(with context: DatabaseContext) -> any Database {
        DummyDatabase(context: context)
    }

    public func shutdown() {
        self.didShutdown.withLockedValue { $0 = true }
    }
    deinit {
        assert(self.didShutdown.withLockedValue { $0 }, "DummyDatabase did not shutdown before deinit.")
    }
}

// MARK: Private

public struct DummyRow: DatabaseOutput {
    public init() { }

    public func schema(_ schema: String) -> any DatabaseOutput {
        self
    }

    public func nested(_ key: FieldKey) throws -> any DatabaseOutput {
        self
    }

    public func decodeNil(_ key: FieldKey) throws -> Bool {
        false
    }
    
    public func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        if T.self is UUID.Type {
            return UUID() as! T
        } else if T.self is Int.Type, key == .aggregate {
            return 1 as! T
        } else {
            return try T(from: DummyDecoder())
        }
    }

    public func contains(_ key: FieldKey) -> Bool {
        true
    }
    
    public var description: String {
        "<dummy>"
    }
}

private struct DummyDecoder: Decoder {
    var codingPath: [any CodingKey] {
        []
    }
    
    var userInfo: [CodingUserInfoKey: Any] {
        [:]
    }
    
    init() {
        
    }
    
    struct KeyedDecoder<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var codingPath: [any CodingKey] {
            []
        }
        
        var allKeys: [Key] {
            [Key(stringValue: "test")!]
        }
        
        init() {}
        
        func contains(_ key: Key) -> Bool {
            false
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            false
        }
        
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            if T.self is UUID.Type {
                return UUID() as! T
            } else {
                return try T.init(from: DummyDecoder())
            }
        }
        
        func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            .init(KeyedDecoder<NestedKey>())
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            UnkeyedDecoder()
        }
        
        func superDecoder() throws -> any Decoder {
            DummyDecoder()
        }
        
        func superDecoder(forKey key: Key) throws -> any Decoder {
            DummyDecoder()
        }
    }
    
    struct UnkeyedDecoder: UnkeyedDecodingContainer {
        var codingPath: [any CodingKey]
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
            true
        }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            try T.init(from: DummyDecoder())
        }
        
        mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
            KeyedDecodingContainer<NestedKey>(KeyedDecoder())
        }
        
        mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
            UnkeyedDecoder()
        }
        
        mutating func superDecoder() throws -> any Decoder {
            DummyDecoder()
        }
    }
    
    struct SingleValueDecoder: SingleValueDecodingContainer {
        var codingPath: [any CodingKey] {
            []
        }
        
        init() {}
        
        func decodeNil() -> Bool {
            false
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            false
        }
        
        func decode(_ type: String.Type) throws -> String {
            "foo"
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            3.14
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            1.59
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            -42
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            -8
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            -16
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            -32
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            -64
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            42
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            8
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            16
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            32
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            64
        }
        
        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            if T.self is UUID.Type {
                return UUID() as! T
            } else {
                return try T(from: DummyDecoder())
            }
        }
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        .init(KeyedDecoder())
    }
    
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        UnkeyedDecoder()
    }
    
    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        SingleValueDecoder()
    }
}
