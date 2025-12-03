import FluentKit
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOEmbedded

/// Lets you mock the row results for each query.
///
/// Make sure you `append` a result for each query you will
/// make to the database. Running out of results will result
/// in a failed `EventLoopFuture` with the
/// `TestDatabaseError.ranOutOfResults` error.
///
/// **Examples:**
///
/// Return an empty result for the next query:
///
///     let db = ArrayTestDatabase()
///     db.append([])
///
/// Return an empty result for first query, and a single result
/// for the second query (perhaps a query to find a record with
/// no results followed by a successful query to create the record):
///
///     let db = ArrayTestDatabase()
///     db.append([])
///     db.append([
///         TestOutput(["id": 1, "name": "Boise"])
///     ])
///
/// Return multiple rows for one query:
///
///     let db = ArrayTestDatabase()
///     db.append([
///         TestOutput(["id": 1, ...]),
///         TestOutput(["id": 2, ...])
///     ])
///
/// Append a `Model`:
///
///     let db = ArrayTestDatabase()
///     db.append([
///         TestOutput(Planet(name: "Pluto"))
///     ])
///
public final class ArrayTestDatabase: TestDatabase {
    let results: NIOLockedValueBox<[[any DatabaseOutput]]>

    public init() {
        self.results = .init([])
    }

    public func append(_ result: [any DatabaseOutput]) {
        self.results.withLockedValue { $0.append(result) }
    }

    public func append<M>(_ result: [M])
    where M: Model {
        self.results.withLockedValue { $0.append(result.map { TestOutput($0) }) }
    }

    public func execute(query: DatabaseQuery, onOutput: @escaping @Sendable (any DatabaseOutput) -> Void) throws {
        guard !self.results.withLockedValue({ $0.isEmpty }) else {
            throw TestDatabaseError.ranOutOfResults
        }
        self.results.withLockedValue {
            for output in $0.removeFirst() {
                onOutput(output)
            }
        }
    }
}

public final class CallbackTestDatabase: TestDatabase {
    let callback: @Sendable (DatabaseQuery) -> [any DatabaseOutput]

    public init(callback: @escaping @Sendable (DatabaseQuery) -> [any DatabaseOutput]) {
        self.callback = callback
    }

    public func execute(query: DatabaseQuery, onOutput: @escaping @Sendable (any DatabaseOutput) -> Void) throws {
        for output in self.callback(query) {
            onOutput(output)
        }
    }
}

public protocol TestDatabase: Sendable {
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> Void
    ) throws
}

extension TestDatabase {
    public var db: any Database {
        self.database(
            context: .init(
                configuration: self.configuration,
                logger: Logger(label: "codes.vapor.fluent.test"),
                eventLoop: EmbeddedEventLoop()
            ))
    }

    public func database(context: DatabaseContext) -> any Database {
        _TestDatabase(test: self, context: context)
    }
}

private struct _TestDatabase: Database {
    var inTransaction: Bool {
        false
    }
    let test: any TestDatabase
    var context: DatabaseContext

    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        guard context.eventLoop.inEventLoop else {
            return self.eventLoop.flatSubmit {
                self.execute(query: query, onOutput: onOutput)
            }
        }
        do {
            try self.test.execute(query: query, onOutput: onOutput)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.eventLoop.makeSucceededFuture(())
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }

    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }
}

extension TestDatabase {
    public var configuration: any DatabaseConfiguration {
        _TestConfiguration(test: self)
    }
}

private struct _TestConfiguration: DatabaseConfiguration {
    let test: any TestDatabase
    var middleware: [any AnyModelMiddleware] = []

    func makeDriver(for databases: Databases) -> any DatabaseDriver {
        _TestDriver(test: self.test)
    }
}

private struct _TestDriver: DatabaseDriver {
    let test: any TestDatabase

    func makeDatabase(with context: DatabaseContext) -> any Database {
        self.test.database(context: context)
    }

    func shutdown() {
        // Do nothing
    }
}

public enum TestDatabaseError: Error {
    case ranOutOfResults
}

public struct TestOutput: DatabaseOutput {
    public func schema(_ schema: String) -> any DatabaseOutput {
        self
    }

    public func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
    where T: Decodable {
        if let res = dummyDecodedFields[key] as? T {
            return res
        }
        throw TestRowDecodeError.wrongType
    }

    public func contains(_ path: FieldKey) -> Bool {
        true
    }

    public func nested(_ key: FieldKey) throws -> any DatabaseOutput {
        self
    }

    public func decodeNil(_ key: FieldKey) throws -> Bool {
        false
    }

    public var description: String {
        "<dummy>"
    }

    var dummyDecodedFields: [FieldKey: any Sendable]

    public init() {
        self.dummyDecodedFields = [:]
    }

    public init(_ mockFields: [FieldKey: any Sendable]) {
        self.dummyDecodedFields = mockFields
    }

    public init<TestModel>(_ model: TestModel)
    where TestModel: Model {
        func unpack(_ dbValue: DatabaseQuery.Value) -> Any? {
            switch dbValue {
            case .null:
                nil
            case .enumCase(let value):
                value
            case .custom(let value):
                value
            case .bind(let value):
                value
            case .array(let array):
                array.map(unpack)
            case .dictionary(let dictionary):
                dictionary.mapValues(unpack)
            case .default:
                ""
            }
        }

        let collect = CollectInput()
        model.input(to: collect)
        self.init(
            collect.storage.mapValues(unpack)
        )
    }

    public mutating func append(key: FieldKey, value: any Sendable) {
        dummyDecodedFields[key] = value
    }
}

private final class CollectInput: DatabaseInput {
    var storage: [FieldKey: DatabaseQuery.Value]

    init() {
        self.storage = [:]
    }

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.storage[key] = value
    }
}

public enum TestRowDecodeError: Error {
    case wrongType
}
