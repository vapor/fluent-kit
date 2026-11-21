import FluentBenchmark
import FluentKit
import Foundation
import NIOConcurrencyHelpers
import SQLKit
import XCTest
import XCTFluent

/// A model type's timestamps are found once and remembered, while every save still stamps the instance it saves.
final class TimestampCacheTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }

    func testEverySaveStampsTheInstanceItSaves() async throws {
        let queries = NIOLockedValueBox<[(action: String, input: [FieldKey: DatabaseQuery.Value])]>([])
        let test = CallbackTestDatabase { query in
            if case .dictionary(let input) = query.input.first {
                queries.withLockedValue { $0.append((action: "\(query.action)", input: input)) }
            }
            return []
        }
        let first = Stamped(name: "first")
        let second = Stamped(name: "second")

        try await first.create(on: test.db)
        try await second.create(on: test.db)

        for stamped in [first, second] {
            XCTAssertNotNil(stamped.createdAt)
            XCTAssertNotNil(stamped.updatedAt)
            XCTAssertNil(stamped.deletedAt)
        }
        for created in queries.withLockedValue({ $0 }) {
            XCTAssertNotNil(created.input["created_at"])
            XCTAssertNotNil(created.input["updated_at"])
            XCTAssertNil(created.input["deleted_at"])
        }

        let secondUpdatedAt = second.updatedAt
        first.name = "renamed"
        first.updatedAt = .distantPast
        try await first.update(on: test.db)

        XCTAssertNotEqual(first.updatedAt, .distantPast)
        XCTAssertEqual(second.updatedAt, secondUpdatedAt)

        try await first.delete(on: test.db)

        XCTAssertNotNil(first.deletedAt)
        XCTAssertNil(second.deletedAt)
        XCTAssertEqual(queries.withLockedValue { $0.last?.action }, "update")

        try await first.restore(on: test.db)

        XCTAssertNil(first.deletedAt)
    }

    func testAnAliasLeavesOutItsModelsDeletedRows() async throws {
        let db = DummyDatabaseForTestSQLSerializer()

        _ = try await Planet.query(on: db)
            .join(OtherPlanet.self, on: \Planet.$id == \OtherPlanet.$id)
            .all(\.$name)

        let sql = try XCTUnwrap(db.sqlSerializers.first?.sql)
        XCTAssert(sql.contains(#"("planets"."deleted_at" IS NULL OR "planets"."deleted_at" > $1)"#), sql)
        XCTAssert(sql.contains(#"("other_planets"."deleted_at" IS NULL OR "other_planets"."deleted_at" > $2)"#), sql)
    }

    func testAModelWithNoSoftDeleteFieldDeletesForGood() async throws {
        let db = DummyDatabaseForTestSQLSerializer()

        try await Unstamped.query(on: db).filter(\.$name == "gone").delete()

        XCTAssertEqual(db.sqlSerializers.first?.sql, #"DELETE FROM "unstamped" WHERE "unstamped"."name" = $1"#)
    }
}

private final class Stamped: Model, @unchecked Sendable {
    static let schema = "stamped"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    init(name: String) {
        self.name = name
    }
}

private final class Unstamped: Model, @unchecked Sendable {
    static let schema = "unstamped"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    init() {}
}

private final class OtherPlanet: ModelAlias {
    static let name = "other_planets"
    let model = Planet()
}
