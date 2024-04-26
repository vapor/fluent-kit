//
//  FilterQueryTests.swift
//  
//
//  Created by Mathew Polzin on 3/8/20.
//

import FluentKit
import FluentBenchmark
import XCTest
import Foundation
import FluentSQL

final class FilterQueryTests: DbQueryTestCase {
    // MARK: Enum
    func test_enumEquals() throws {
        _ = try Task.query(on: self.db).filter(\.$status == .done).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" = 'done'"#)
    }

    func test_enumNotEquals() throws {
        _ = try Task.query(on: self.db).filter(\.$status != .done).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" <> 'done'"#)
    }

    func test_enumIn() throws {
        _ = try Task.query(on: self.db).filter(\.$status ~~ [.done, .notDone]).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" IN ('done','notDone')"#)
    }

    func test_enumNotIn() throws {
        _ = try Task.query(on: self.db).filter(\.$status !~ [.done, .notDone]).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."status" NOT IN ('done','notDone')"#)
    }
    
    // MARK: OptionalEnum
    func test_optionalEnumEquals() throws {
        _ = try Task.query(on: self.db).filter(\.$optionalStatus == .done).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" = 'done'"#)
    }

    func test_optionalEnumNotEquals() throws {
        _ = try Task.query(on: self.db).filter(\.$optionalStatus != .done).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" <> 'done'"#)
    }

    func test_optionalEnumIn() throws {
        _ = try Task.query(on: self.db).filter(\.$optionalStatus ~~ [.done, .notDone]).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" IN ('done','notDone')"#)
    }

    func test_optionalEnumNotIn() throws {
        _ = try Task.query(on: self.db).filter(\.$optionalStatus !~ [.done, .notDone]).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."optional_status" NOT IN ('done','notDone')"#)
    }

    // MARK: String
    func test_stringEquals() throws {
        _ = try Task.query(on: self.db).filter(\.$description == "hello").all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" = $1"#)
    }

    func test_stringNotEquals() throws {
        _ = try Task.query(on: self.db).filter(\.$description != "hello").all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" <> $1"#)
    }

    func test_stringIn() throws {
        _ = try Task.query(on: self.db).filter(\.$description ~~ ["hello"]).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" IN ($1)"#)
    }

    func test_stringNotIn() throws {
        _ = try Task.query(on: self.db).filter(\.$description !~ ["hello"]).all().wait()
        assertQuery(self.db, #"SELECT "tasks"."id" AS "tasks_id", "tasks"."description" AS "tasks_description", "tasks"."status" AS "tasks_status", "tasks"."optional_status" AS "tasks_optional_status" FROM "tasks" WHERE "tasks"."description" NOT IN ($1)"#)
    }
}

enum Diggity: String, Codable {
    case done, notDone
}

final class Task: Model, @unchecked Sendable {
    static let schema = "tasks"

    @ID(custom: "id", generatedBy: .user)
    var id: Int?

    @Field(key: "description")
    var description: String

    @Enum(key: "status")
    var status: Diggity
    
    @OptionalEnum(key: "optional_status")
    var optionalStatus: Diggity?

    init() {}
}
