import FluentKit
import FluentSQL
import Foundation
import XCTest

final class OptionalEnumQueryTests: DbQueryTestCase {
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }
    
    func testInsertNonNull() throws {
        _ = try Thing(id: 1, fb: .fizz).create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, 'fizz')"#)
    }
    
    func testInsertNull() throws {
        _ = try Thing(id: 1, fb: nil).create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, NULL)"#)
    }
    
    func testBulkUpdateDoesntOverkill() throws {
        let thing = Thing(id: 1, fb: .buzz)
        try thing.create(on: db).wait()
        try Thing.query(on: db).filter(\.$id != thing.id!).set(\.$id, to: 99).update().wait()
        assertLastQuery(db, #"UPDATE "things" SET "id" = $1 WHERE "things"."id" <> $2"#)
    }
    
    func testInsertAfterMutatingNullableField() throws {
        let thing = Thing(id: 1, fb: nil)
        thing.fb = .fizz
        _ = try thing.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, 'fizz')"#)
        
        let thing2 = Thing(id: 1, fb: .buzz)
        thing2.fb = nil
        _ = try thing2.create(on: db).wait()
        assertLastQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, NULL)"#)
    }
    
    func testSaveReplacingNonNull() throws {
        let thing = Thing(id: 1, fb: .fizz)
        _ = try thing.create(on: db).wait()
        thing.fb = .buzz
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "fb" = 'buzz' WHERE "things"."id" = $1"#)
    }
    
    func testSaveReplacingNull() throws {
        let thing = Thing(id: 1, fb: nil)
        _ = try thing.create(on: db).wait()
        thing.fb = .fizz
        _ = try thing.save(on: db).wait()
        assertLastQuery(db, #"UPDATE "things" SET "fb" = 'fizz' WHERE "things"."id" = $1"#)
    }
    
    // @see https://github.com/vapor/fluent-kit/issues/444
    func testSaveNullReplacingNonNull() throws {
        let thing = Thing(id: 1, fb: .fizz)
        _ = try thing.create(on: db).wait()
        thing.fb = nil
        _ = try thing.save(on: db).wait()
        XCTAssertNil(thing.fb)
        assertLastQuery(db, #"UPDATE "things" SET "fb" = NULL WHERE "things"."id" = $1"#)
    }
    
    func testBulkInsertWithoutNulls() throws {
        let things = [Thing(id: 1, fb: .fizz), Thing(id: 2, fb: .buzz)]
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, 'fizz'), ($2, 'buzz')"#)
    }
    
    func testBulkInsertWithOnlyNulls() throws {
        let things = [Thing(id: 1, fb: nil), Thing(id: 2, fb: nil)]
        _ = try things.create(on: db).wait()
        assertQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, NULL), ($2, NULL)"#)
    }
    
    // @see https://github.com/vapor/fluent-kit/issues/396
    func testBulkInsertWithMixedNulls() throws {
        let things = [Thing(id: 1, fb: nil), Thing(id: 2, fb: .fizz)]
        _ = try things.create(on: db).wait()
        assertLastQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, NULL), ($2, 'fizz')"#)

        let things2 = [Thing(id: 3, fb: .fizz), Thing(id: 4, fb: nil)]
        _ = try things2.create(on: db).wait()
        assertLastQuery(db, #"INSERT INTO "things" ("id", "fb") VALUES ($1, 'fizz'), ($2, NULL)"#)
    }
}

private final class Thing: Model, @unchecked Sendable {
    enum FizzBuzz: String, Codable {
        case fizz
        case buzz
    }

    static let schema = "things"
    
    @ID(custom: "id", generatedBy: .user)
    var id: Int?
    
    @OptionalEnum(key: "fb")
    var fb: FizzBuzz?
    
    init() {}
    
    init(id: Int, fb: FizzBuzz? = nil) {
        self.id = id
        self.fb = fb
    }
}
