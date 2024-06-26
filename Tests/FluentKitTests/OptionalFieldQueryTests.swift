import FluentKit
import FluentSQL
import Foundation
import XCTest

final class OptionalFieldQueryTests: DbQueryTestCase {
    func testInsertNonNull() throws {
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try Thing(id: 1, name: "Jared").create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "name") VALUES ($1, $2)"#)
    }
    
    func testInsertNull() throws {
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try Thing(id: 1, name: nil).create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "name") VALUES ($1, NULL)"#)
    }
    
    func testInsertAfterMutatingNullableField() throws {
        let thing = Thing(id: 1, name: nil)
        thing.name = "Jared"
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try thing.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "name") VALUES ($1, $2)"#)
        
        db.reset()
        
        let thing2 = Thing(id: 1, name: "Jared")
        thing2.name = nil
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try thing2.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "name") VALUES ($1, NULL)"#)
    }
    
    func testSaveReplacingNonNull() throws {
        let thing = Thing(id: 1, name: "Jared")
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try thing.create(on: db).wait()
        thing.name = "Bob"
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "name" = $1 WHERE "things"."id" = $2"#)
    }
    
    func testSaveReplacingNull() throws {
        let thing = Thing(id: 1, name: nil)
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try thing.create(on: db).wait()
        thing.name = "Bob"
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "name" = $1 WHERE "things"."id" = $2"#)
    }
    
    func testSaveNullReplacingNonNull() throws {
        let thing = Thing(id: 1, name: "Jared")
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try thing.create(on: db).wait()
        thing.name = nil
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "name" = NULL WHERE "things"."id" = $1"#)
    }
    
    func testBulkInsertWithoutNulls() throws {
        let things = [Thing(id: 1, name: "Jared"), Thing(id: 2, name: "Bob")]
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "name") VALUES ($1, $2), ($3, $4)"#)
    }
    
    func testBulkInsertWithOnlyNulls() throws {
        let things = [Thing(id: 1, name: nil), Thing(id: 2, name: nil)]
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "name") VALUES ($1, NULL), ($2, NULL)"#)
    }
    
    func testBulkInsertWithMixedNulls() throws {
        let things = [Thing(id: 1, name: "Jared"), Thing(id: 2, name: nil)]
        db.fakedRows.append([.init(["id": UUID()])])
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "name") VALUES ($1, $2), ($3, NULL)"#)
    }
}

private final class Thing: Model, @unchecked Sendable {
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
