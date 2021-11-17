@testable import FluentKit
import FluentSQL
import Foundation
import XCTest

final class OptionalFieldQueryTests: DbQueryTestCase {
    
    func testInsertNonNull() throws {
        _ = try Thing(id: 1, name: "Jared").create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("name", "id") VALUES ($1, $2)"#)
    }
    
    func testInsertNull() throws {
        _ = try Thing(id: 1, name: nil).create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("name", "id") VALUES (NULL, $1)"#)
    }
    
    func testInsertAfterMutatingNullableField() throws {
        let thing = Thing(id: 1, name: nil)
        thing.name = "Jared"
        _ = try thing.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("name", "id") VALUES ($1, $2)"#)
        
        db.reset()
        
        let thing2 = Thing(id: 1, name: "Jared")
        thing2.name = nil
        _ = try thing2.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("name", "id") VALUES (NULL, $1)"#)
    }
    
    func testSaveReplacingNonNull() throws {
        let thing = Thing(id: 1, name: "Jared")
        _ = try thing.create(on: db).wait()
        thing.name = "Bob"
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "name" = $1 WHERE "things"."id" = $2"#)
    }
    
    func testSaveReplacingNull() throws {
        let thing = Thing(id: 1, name: nil)
        _ = try thing.create(on: db).wait()
        thing.name = "Bob"
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "name" = $1 WHERE "things"."id" = $2"#)
    }
    
    func testSaveNullReplacingNonNull() throws {
        let thing = Thing(id: 1, name: "Jared")
        _ = try thing.create(on: db).wait()
        thing.name = nil
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "name" = NULL WHERE "things"."id" = $1"#)
    }
    
    func testBulkInsertWithoutNulls() throws {
        let things = [Thing(id: 1, name: "Jared"), Thing(id: 2, name: "Bob")]
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("name", "id") VALUES ($1, $2), ($3, $4)"#)
    }
    
    func testBulkInsertWithOnlyNulls() throws {
        let things = [Thing(id: 1, name: nil), Thing(id: 2, name: nil)]
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("name", "id") VALUES (NULL, $1), (NULL, $2)"#)
    }
    
    func testBulkInsertWithMixedNulls() throws {
        let things = [Thing(id: 1, name: "Jared"), Thing(id: 2, name: nil)]
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("name", "id") VALUES ($1, $2), (NULL, $3)"#)
    }
}

private final class Thing: Model {
    static let schema = "things"

    @ID(custom: "id", generatedBy: .user)
    var id: Int?

    @OptionalField(key: "name")
    var name: String?

    init() {}

    init(id: Int, name: String? = nil) {
        self.id = id
        self.name = name
    }
}
