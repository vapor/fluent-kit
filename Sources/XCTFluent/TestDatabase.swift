import FluentKit
import NIO

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
///     let db = TestDatabase()
///     db.append(queryResult: [])
///
/// Return an empty result for first query, and a single result
/// for the second query (perhaps a query to find a record with
/// no results followed by a successful query to create the record):
///
///     let db = TestDatabase()
///     db.append(queryResult: [])
///     db.append(queryResult: [
///         TestOutput(["id": 1, "name": "Boise"])
///     ])
///
/// Return multiple rows for one query:
///
///     let db = TestDatabase()
///     db.append([
///         TestOutput(["id": 1, ...]),
///         TestOutput(["id": 2, ...])
///     ])
public class TestDatabase: Database {

    typealias MockResult = [DatabaseOutput]

    var mockResults: [MockResult] = []

    public var context: DatabaseContext

    public init(
        context: DatabaseContext = .init(
            configuration: TestDatabaseConfiguration(),
            logger: .init(label: "test"),
            eventLoop: EmbeddedEventLoop()
        )
    ) {
        self.context = context
    }

    /// Add a new mock result to the database. One mock result will
    /// be returned per query to the database. Running out of results
    /// will result in a failed `EventLoopFuture` with the
    /// `TestDatabaseError.ranOutOfResults` error.
    public func append(queryResult: [DatabaseOutput]) {
        mockResults.append(queryResult)
    }

    public func execute(
        query: DatabaseQuery,
        onOutput: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {

        guard !mockResults.isEmpty else {
            return self.eventLoop.makeFailedFuture(TestDatabaseError.ranOutOfResults)
        }

        let result = mockResults.removeFirst()

        for row in result {
            onOutput(row)
        }
        return self.eventLoop.makeSucceededFuture(())
    }

    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }

    public func withConnection<T>(_ closure: (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }

    public func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }

    public func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }
}

public enum TestDatabaseError: Error {
    case ranOutOfResults
}

public struct TestOutput: DatabaseOutput {
    public func schema(_ schema: String) -> DatabaseOutput {
        self
    }

    public func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T: Decodable
    {
        if let res = dummyDecodedFields[path] as? T {
            return res
        }
        throw TestRowDecodeError.wrongType
    }

    public func contains(_ path: [FieldKey]) -> Bool {
        return true
    }

    public var description: String {
        return "<dummy>"
    }

    var dummyDecodedFields: [[FieldKey]: Any]

    public init(_ mockFields: [[FieldKey]: Any]) {
        self.dummyDecodedFields = mockFields
    }

    public init(_ mockFields: [FieldKey: Any]) {
        self.dummyDecodedFields = Dictionary(
            mockFields.map { (k, v) in ([k], v) },
            uniquingKeysWith: { $1 }
        )
    }

    public mutating func append(key: [FieldKey], value: Any) {
        dummyDecodedFields[key] = value
    }

    public mutating func append(key: FieldKey, value: Any) {
        dummyDecodedFields[[key]] = value
    }
}

public enum TestRowDecodeError: Error {
    case wrongType
}

public struct TestDatabaseConfiguration: DatabaseConfiguration {
    public var middleware: [AnyModelMiddleware]

    public func makeDriver(for databases: Databases) -> DatabaseDriver {
        DummyDatabaseDriver(on: databases.eventLoopGroup)
    }

    public init(middleware: [AnyModelMiddleware] = []) {
        self.middleware = middleware
    }
}
