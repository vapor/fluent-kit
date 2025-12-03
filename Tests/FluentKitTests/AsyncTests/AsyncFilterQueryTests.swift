import FluentBenchmark
import FluentKit
import FluentSQL
import Foundation
import XCTest

final class AsyncFilterQueryTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }

    // MARK: Enum
    func test_enumEquals() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$status == .done).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" = 'done'"#
        )
        db.reset()
    }

    func test_enumNotEquals() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$status != .done).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" <> 'done'"#
        )
        db.reset()
    }

    func test_enumIn() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$status ~~ [.done, .notDone]).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" IN ('done','notDone')"#
        )
        db.reset()
    }

    func test_enumNotIn() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$status !~ [.done, .notDone]).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" NOT IN ('done','notDone')"#
        )
        db.reset()
    }

    // MARK: OptionalEnum
    func test_optionalEnumEquals() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$optionalStatus == .done).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" = 'done'"#
        )
        db.reset()
    }

    func test_optionalEnumNotEquals() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$optionalStatus != .done).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" <> 'done'"#
        )
        db.reset()
    }

    func test_optionalEnumIn() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$optionalStatus ~~ [.done, .notDone]).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" IN ('done','notDone')"#
        )
        db.reset()
    }

    func test_optionalEnumNotIn() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$optionalStatus !~ [.done, .notDone]).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" NOT IN ('done','notDone')"#
        )
        db.reset()
    }

    // MARK: String
    func test_stringEquals() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$description == "hello").all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" = $1"#
        )
        db.reset()
    }

    func test_stringNotEquals() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$description != "hello").all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" <> $1"#
        )
        db.reset()
    }

    func test_stringIn() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$description ~~ ["hello"]).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" IN ($1)"#
        )
        db.reset()
    }

    func test_stringNotIn() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Task.query(on: db).filter(\.$description !~ ["hello"]).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(
            db.sqlSerializers.first?.sql,
            #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" NOT IN ($1)"#
        )
        db.reset()
    }
}
