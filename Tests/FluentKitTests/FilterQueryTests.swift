//
//  FilterQueryTests.swift
//  
//
//  Created by Mathew Polzin on 3/8/20.
//

@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation
import FluentSQL

final class FilterQueryTests: XCTestCase {
    // MARK: Enum
    func test_enumEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$status == .done).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."status" = 'done'"#)
        db.reset()
    }

    func test_enumNotEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$status != .done).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."status" <> 'done'"#)
        db.reset()
    }

    func test_enumIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$status ~~ [.done, .notDone]).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."status" IN ('done' , 'notDone')"#)
        db.reset()
    }

    func test_enumNotIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$status !~ [.done, .notDone]).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."status" NOT IN ('done' , 'notDone')"#)
        db.reset()
    }
    
    // MARK: OptionalEnum
    func test_optionalEnumEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$priority == .low).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."priority" = 'low'"#)
        db.reset()
    }

    func test_optionalEnumNotEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$priority != .low).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."priority" <> 'low'"#)
        db.reset()
    }

    func test_optionalEnumIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$priority ~~ [.low, .mid]).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."priority" IN ('low' , 'mid')"#)
        db.reset()
    }

    func test_optionalEnumNotIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$priority !~ [.low, .mid]).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."priority" NOT IN ('low' , 'mid')"#)
        db.reset()
    }

    // MARK: String
    func test_stringEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description == "hello").all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."description" = $1"#)
        db.reset()
    }

    func test_stringNotEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description != "hello").all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."description" <> $1"#)
        db.reset()
    }

    func test_stringIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description ~~ ["hello"]).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."description" IN ($1)"#)
        db.reset()
    }

    func test_stringNotIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description !~ ["hello"]).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."priority" AS "tasks_priority" FROM "tasks" WHERE "tasks"."description" NOT IN ($1)"#)
        db.reset()
    }
}

enum Diggity: String, Codable {
    case done, notDone
}

enum Priority: String, Codable {
    case low, mid, urgent
}

final class Task: Model {
    static let schema = "tasks"

    @ID(custom: "id", generatedBy: .user)
    var id: Int?

    @Field(key: "description")
    var description: String

    @Enum(key: "status")
    var status: Diggity
    
    @OptionalEnum(key: "priority")
    var priority: Priority?

    init() {}

    init(id: Int, status: Diggity, description: String, priority: Priority?) {
        self.id = id
        self.status = status
        self.description = description
        self.priority = priority
    }
}
