@testable import FluentKit
import NIO
import SQLKit

/// Lets you determine the row results for each query.
///
/// Initialize with an array or arrays, each inner array
/// containing all the rows for a certain query result. Each
/// new query will produce the next inner-array of results.
///
/// You can specify an empty result-set (as is correct for
/// some queries and useful for other tests) with an empty
/// inner-array.
///
/// Examples:
///
/// Return an empty result for all queries:
///
///     DummyDatabaseForTestQueries(mockResults: [[]])
///
/// Return an empty result for first query, and a single result
/// for the second query (perhaps a query to find a record with
/// no results followed by a successful query to create the record):
///
///     DummyDatabaseForTestQueries(mockResults: [
///         [],
///         [
///             DummyDatabaseForTestQueries.DummyRow(dummyDecodedFields: ["id": 1, "name": "Boise"])
///         ]
///     ])
public class DummyDatabaseForTestQueries: Database {

    public typealias MockResult = [DatabaseRow]

    let mockResults: [MockResult]
    var resultIdx: Int = 0

    public var dialect: SQLDialect {
        DummyDatabaseDialect()
    }
    public var context: DatabaseContext

    public init(
        mockResults: [MockResult] = [[]],
        context: DatabaseContext = .init(
            configuration: .init(),
            logger: .init(label: "test"),
            eventLoop: EmbeddedEventLoop()
        )
    ) {
        precondition(mockResults.count > 0, "An empty array of results is not supported. Did you mean to pass 1 empty result (i.e. `[[]]`)?")
        self.context = context
        self.mockResults = mockResults
    }

    public func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        defer { resultIdx = (resultIdx + 1) % mockResults.count }

        for row in mockResults[resultIdx] {
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

    public enum DummyDecodeError: Error {
        case wrongType
    }

    public struct DummyRow: DatabaseRow {
        public func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T
            where T: Decodable
        {
            if let res = dummyDecodedFields[field] as? T {
                return res
            }
            throw DummyDecodeError.wrongType
        }

        public func contains(field: String) -> Bool {
            return true
        }

        public var description: String {
            return "<dummy>"
        }

        let dummyDecodedFields: [String: Any]
    }
}
