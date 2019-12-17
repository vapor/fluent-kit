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
///         TestRow(["id": 1, "name": "Boise"])
///     ])
///
/// Return multiple rows for one query:
///
///     let db = TestDatabase()
///     db.append([
///         TestRow(["id": 1, ...]),
///         TestRow(["id": 2, ...])
///     ])
public class TestDatabase: Database {

    typealias MockResult = [DatabaseRow]

    var mockResults: [MockResult] = []

    public var context: DatabaseContext

    public init(
        context: DatabaseContext = .init(
            configuration: .init(),
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
    public func append(queryResult: [DatabaseRow]) {
        mockResults.append(queryResult)
    }

    public func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {

        guard !mockResults.isEmpty else {
            return self.eventLoop.makeFailedFuture(TestDatabaseError.ranOutOfResults)
        }

        let result = mockResults.removeFirst()

        for row in result {
            onRow(row)
        }
        return self.eventLoop.makeSucceededFuture(())
    }

    public func withConnection<T>(_ closure: (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }

    public func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }
}

public enum TestDatabaseError: Error {
    case ranOutOfResults
}

public struct TestRow: DatabaseRow {
    public func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T
        where T: Decodable
    {
        if let res = dummyDecodedFields[field] as? T {
            return res
        }
        throw TestRowDecodeError.wrongType
    }

    public func contains(field: String) -> Bool {
        return true
    }

    public var description: String {
        return "<dummy>"
    }

    var dummyDecodedFields: [String: Any]

    public init(_ mockFields: [String: Any]) {
        self.dummyDecodedFields = mockFields
    }
}

public enum TestRowDecodeError: Error {
    case wrongType
}
