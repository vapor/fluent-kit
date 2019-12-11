import NIO
@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation
import FluentSQL

final class QueryBuilderTests: XCTestCase {
    func testFirstOrCreateFindsResult() throws {
        let existingPlanet = Planet3(id: 1, name: "Nupeter", galaxyID: 10)
        let newPlanet = Planet3(id: 2, name: "Marzipan", galaxyID: 10)
        // first and only result contains existing row
        let db = DummyDatabase(mockResults: [[
            DummyRow(dummyDecodedFields: [
                "id": try existingPlanet.requireID(),
                "name": existingPlanet.name,
                "galaxy_id": existingPlanet.$galaxy.id
            ])
        ]])

        let retrievedPlanet = try Planet3.query(on: db).first(orCreate: newPlanet).wait()

        XCTAssertEqual(retrievedPlanet.name, existingPlanet.name)
        XCTAssertEqual(try retrievedPlanet.requireID(), try existingPlanet.requireID())
    }

    func testFirstOrCreateCreatesResult() throws {
        let planet = Planet3(id: 1, name: "Nupeter", galaxyID: 10)
        // first result is empty, second result contains created row
        let db = DummyDatabase(mockResults: [[], [
            DummyRow(dummyDecodedFields: [
                "id": try planet.requireID(),
                "name": planet.name,
                "galaxy_id": planet.$galaxy.id
            ])
        ]])

        let retrievedPlanet = try Planet3.query(on: db).first(orCreate: planet).wait()

        XCTAssertEqual(retrievedPlanet.name, planet.name)
        XCTAssertEqual(try retrievedPlanet.requireID(), try planet.requireID())
    }

    func testFirstOrCreatePropagatesError() throws {
        // pretend a query results in a field of the wrong type
        let planet = Planet3(id: 1, name: "Nupeter", galaxyID: 10)
        let db = DummyDatabase(mockResults: [[
            DummyRow(dummyDecodedFields: [
                "id": "hello", // wrong type here
                "name": planet.name,
                "galaxy_id": planet.$galaxy.id
            ])
        ]])

        XCTAssertThrowsError(try Planet3.query(on: db).first(orCreate: planet).wait())
    }
}

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
///     DummyDatabase(mockResults: [[]])
///
/// Return an empty result for first query, and a single result
/// for the second query (perhaps a query to find a record with
/// no results followed by a successful query to create the record):
///
///     DummyDatabase(mockResults: [
///         [],
///         [
///             DummyRow(dummyDecodedFields: ["id": 1, "name": "Boise"])
///         ]
///     ])
fileprivate class DummyDatabase: Database {

    typealias MockResult = [DatabaseRow]

    let mockResults: [MockResult]
    var resultIdx: Int = 0

    public var dialect: SQLDialect {
        DummyDatabaseDialect()
    }
    public var context: DatabaseContext

    public init(
        mockResults: [MockResult],
        context: DatabaseContext = .init(
            configuration: .init(),
            logger: .init(label: "test"),
            eventLoop: EmbeddedEventLoop()
        )
    ) {
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
}

fileprivate enum DummyDecodeError: Error {
    case wrongType
}

fileprivate struct DummyRow: DatabaseRow {
    func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T
        where T: Decodable
    {
        if let res = dummyDecodedFields[field] as? T {
            return res
        }
        throw DummyDecodeError.wrongType
    }

    func contains(field: String) -> Bool {
        return true
    }

    var description: String {
        return "<dummy>"
    }

    let dummyDecodedFields: [String: Any]
}

/// Same as FluentBenchmark.Planet except the ID is user generated.
fileprivate final class Planet3: Model {
    static let schema = "planets"

    @ID(key: "id", generatedBy: .user)
    var id: Int?

    @Field(key: "name")
    var name: String

    @Parent(key: "galaxy_id")
    public var galaxy: Galaxy

    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]

    init() { }

    public init(id: Int? = nil, name: String, galaxyID: Galaxy.IDValue) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
