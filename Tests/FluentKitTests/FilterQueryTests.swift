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
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."status" = 'done'"#)
        db.reset()
    }

    func test_enumNotEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$status != .done).all().wait()
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."status" <> 'done'"#)
        db.reset()
    }

    func test_enumIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$status ~~ [.done, .notDone]).all().wait()
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."status" IN ('done' , 'notDone')"#)
        db.reset()
    }

    func test_enumNotIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$status !~ [.done, .notDone]).all().wait()
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."status" NOT IN ('done' , 'notDone')"#)
        db.reset()
    }

    // MARK: String
    func test_stringEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description == "hello").all().wait()
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."description" = $1"#)
        db.reset()
    }

    func test_stringNotEquals() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description != "hello").all().wait()
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."description" <> $1"#)
        db.reset()
    }

    func test_stringIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description ~~ ["hello"]).all().wait()
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."description" IN ($1)"#)
        db.reset()
    }

    func test_stringNotIn() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Task.query(on: db).filter(\.$description !~ ["hello"]).all().wait()
        let t = Task.schemaOrAlias
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "\#(t)"."id" AS "\#(t)_id", "\#(t)"."description" AS "\#(t)_description", "\#(t)"."status" AS "\#(t)_status" FROM "tasks" AS "\#(t)" WHERE "\#(t)"."description" NOT IN ($1)"#)
        db.reset()
    }
}

enum Diggity: String, Codable {
    case done, notDone
}

final class Task: Model {
    static let schema = "tasks"

    @ID(custom: "id", generatedBy: .user)
    var id: Int?

    @Field(key: "description")
    var description: String

    @Enum(key: "status")
    var status: Diggity

    init() {}

    init(id: Int, status: Diggity, description: String) {
        self.id = id
        self.status = status
        self.description = description
    }
}
