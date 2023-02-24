import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testEnum() throws {
        try self.testEnum_basic()
        try self.testEnum_addCases()
        try self.testEnum_raw()
        try self.testEnum_queryFound()
        try self.testEnum_queryMissing()
        try self.testEnum_decode()
        
        // Note: These should really be in their own top-level test case, but then I'd have to open
        // PRs against all the drivers again.
        try self.testBooleanProperties()
    }

    private func testEnum_basic() throws {
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz, baz: .qux)
            XCTAssertTrue(foo.hasChanges)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
            XCTAssertEqual(fetched?.baz, .qux)
            XCTAssertEqual(fetched?.hasChanges, false)
        }
    }

    private func testEnum_addCases() throws {
        try self.runTest(#function, [
            FooMigration(),
            BarAddQuzAndQuzzMigration()
        ]) {
            let foo = Foo(bar: .quz, baz: .quzz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .quz)
            XCTAssertEqual(fetched?.baz, .quzz)
        }
    }

    public func testEnum_raw() throws {
        try runTest(#function, [
            PetMigration()
        ]) {
            let pet = Pet(type: .cat)
            try pet.save(on: self.database).wait()

            let fetched = try Pet.find(pet.id, on: self.database).wait()
            XCTAssertEqual(fetched?.type, .cat)
        }
    }

    public func testEnum_queryFound() throws {
        // equal
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz, baz: .qux)
            try foo.save(on: self.database).wait()

            let fetched = try Foo
                .query(on: self.database)
                .filter(\.$bar == .baz)
                .first()
                .wait()
            XCTAssertEqual(fetched?.bar, .baz)
            XCTAssertEqual(fetched?.baz, .qux)

            // not equal
            let foo2 = Foo(bar: .baz, baz: .qux)
            try foo2.save(on: self.database).wait()

            let fetched2 = try Foo
                .query(on: self.database)
                .filter(\.$bar != .qux)
                .first()
                .wait()
            XCTAssertEqual(fetched2?.bar, .baz)
            XCTAssertEqual(fetched2?.baz, .qux)

            // in
            let foo3 = Foo(bar: .baz, baz: .qux)
            try foo3.save(on: self.database).wait()

            let fetched3 = try Foo
                .query(on: self.database)
                .filter(\.$bar ~~ [.baz, .qux])
                .first()
                .wait()
            XCTAssertEqual(fetched3?.bar, .baz)
            XCTAssertEqual(fetched3?.baz, .qux)

            // not in
            let foo4 = Foo(bar: .baz, baz: .qux)
            try foo4.save(on: self.database).wait()

            let fetched4 = try Foo
                .query(on: self.database)
                .filter(\.$bar !~ [.qux])
                .first()
                .wait()
            XCTAssertEqual(fetched4?.bar, .baz)
            XCTAssertEqual(fetched4?.baz, .qux)
            
            // is null
            let foo5 = Foo(bar: .baz, baz: nil)
            try foo5.save(on: self.database).wait()
            
            let fetched5 = try Foo
                .query(on: self.database)
                .filter(\.$baz == .null)
                .first()
                .wait()
            XCTAssertEqual(fetched5?.bar, .baz)
            XCTAssertNil(fetched5?.baz)
            
            // is not null
            let foo6 = Foo(bar: .baz, baz: .qux)
            try foo6.save(on: self.database).wait()
            
            let fetched6 = try Foo
                .query(on: self.database)
                .filter(\.$baz != .null)
                .first()
                .wait()
            XCTAssertEqual(fetched6?.bar, .baz)
            XCTAssertEqual(fetched6?.baz, .qux)
        }
    }

    public func testEnum_queryMissing() throws {
        // equal
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz, baz: .qux)
            try foo.save(on: self.database).wait()

            let fetched = try Foo
                .query(on: self.database)
                .filter(\.$bar == .qux)
                .first()
                .wait()
            XCTAssertNil(fetched)

            // not equal
            let foo2 = Foo(bar: .baz, baz: .qux)
            try foo2.save(on: self.database).wait()

            let fetched2 = try Foo
                .query(on: self.database)
                .filter(\.$bar != .baz)
                .first()
                .wait()
            XCTAssertNil(fetched2)

            // in
            let foo3 = Foo(bar: .baz, baz: .qux)
            try foo3.save(on: self.database).wait()

            let fetched3 = try Foo
                .query(on: self.database)
                .filter(\.$bar ~~ [.qux])
                .first()
                .wait()
            XCTAssertNil(fetched3)

            // not in
            let foo4 = Foo(bar: .baz, baz: .qux)
            try foo4.save(on: self.database).wait()

            let fetched4 = try Foo
                .query(on: self.database)
                .filter(\.$bar !~ [.baz, .qux])
                .first()
                .wait()
            XCTAssertNil(fetched4)
            
            // is null
            let foo5 = Foo(bar: .baz, baz: .qux)
            try foo5.save(on: self.database).wait()

            let fetched5 = try Foo
                .query(on: self.database)
                .filter(\.$baz == .null)
                .first()
                .wait()
            XCTAssertNil(fetched5)
            
            // is not null
            let foo6 = Foo(bar: .qux, baz: nil)
            try foo6.save(on: self.database).wait()

            let fetched6 = try Foo
                .query(on: self.database)
                .filter(\.$bar == .qux)
                .filter(\.$baz != .null)
                .first()
                .wait()
            XCTAssertNil(fetched6)
        }
    }

    public func testEnum_decode() throws {
        try runTest(#function, [
            FooMigration()
        ]) {
            let data = """
            { "bar": "baz", "baz": "qux" }
            """
            let foo = try JSONDecoder().decode(Foo.self, from: .init(data.utf8))
            try foo.create(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
            XCTAssertEqual(fetched?.baz, .qux)
        }
    }
    
    public func testBooleanProperties() throws {
        try runTest(#function, [
            FlagsMigration()
        ]) {
            let flags1 = Flags(inquired: true, required: true, desired: true, expired: true, inspired: true, retired: true),
                flags2 = Flags(inquired: false, required: false, desired: false, expired: false, inspired: false, retired: false),
                flags3 = Flags(inquired: true, required: true, desired: true, expired: nil, inspired: nil, retired: nil)
            
            try flags1.create(on: self.database).wait()
            try flags2.create(on: self.database).wait()
            try flags3.create(on: self.database).wait()
            
            let rawFlags1 = try XCTUnwrap(RawFlags.find(flags1.id!, on: self.database).wait()),
                rawFlags2 = try XCTUnwrap(RawFlags.find(flags2.id!, on: self.database).wait()),
                rawFlags3 = try XCTUnwrap(RawFlags.find(flags3.id!, on: self.database).wait())
            
            XCTAssertEqual(rawFlags1.inquired, true)
            XCTAssertEqual(rawFlags1.required, 1)
            XCTAssertEqual(rawFlags1.desired, "true")
            XCTAssertEqual(rawFlags1.expired, true)
            XCTAssertEqual(rawFlags1.inspired, 1)
            XCTAssertEqual(rawFlags1.retired, "true")

            XCTAssertEqual(rawFlags2.inquired, false)
            XCTAssertEqual(rawFlags2.required, 0)
            XCTAssertEqual(rawFlags2.desired, "false")
            XCTAssertEqual(rawFlags2.expired, false)
            XCTAssertEqual(rawFlags2.inspired, 0)
            XCTAssertEqual(rawFlags2.retired, "false")

            XCTAssertEqual(rawFlags3.inquired, true)
            XCTAssertEqual(rawFlags3.required, 1)
            XCTAssertEqual(rawFlags3.desired, "true")
            XCTAssertNil(rawFlags3.expired)
            XCTAssertNil(rawFlags3.inspired)
            XCTAssertNil(rawFlags3.retired)

            let savedFlags1 = try XCTUnwrap(Flags.find(flags1.id!, on: self.database).wait()),
                savedFlags2 = try XCTUnwrap(Flags.find(flags2.id!, on: self.database).wait()),
                savedFlags3 = try XCTUnwrap(Flags.find(flags3.id!, on: self.database).wait())
            
            XCTAssertEqual(savedFlags1.inquired, flags1.inquired)
            XCTAssertEqual(savedFlags1.required, flags1.required)
            XCTAssertEqual(savedFlags1.desired, flags1.desired)
            XCTAssertEqual(savedFlags1.expired, flags1.expired)
            XCTAssertEqual(savedFlags1.inspired, flags1.inspired)
            XCTAssertEqual(savedFlags1.retired, flags1.retired)

            XCTAssertEqual(savedFlags2.inquired, flags2.inquired)
            XCTAssertEqual(savedFlags2.required, flags2.required)
            XCTAssertEqual(savedFlags2.desired, flags2.desired)
            XCTAssertEqual(savedFlags2.expired, flags2.expired)
            XCTAssertEqual(savedFlags2.inspired, flags2.inspired)
            XCTAssertEqual(savedFlags2.retired, flags2.retired)

            XCTAssertEqual(savedFlags3.inquired, flags3.inquired)
            XCTAssertEqual(savedFlags3.required, flags3.required)
            XCTAssertEqual(savedFlags3.desired, flags3.desired)
            XCTAssertEqual(savedFlags3.expired, flags3.expired)
            XCTAssertEqual(savedFlags3.inspired, flags3.inspired)
            XCTAssertEqual(savedFlags3.retired, flags3.retired)
        }
    }
}

private enum Bar: String, Codable {
    case baz, qux, quz, quzz
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "bar")
    var bar: Bar
    
    @OptionalEnum(key: "baz")
    var baz: Bar?

    init() { }

    init(id: IDValue? = nil, bar: Bar, baz: Bar?) {
        self.id = id
        self.bar = bar
        self.baz = baz
    }
}


private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("bar")
            .case("baz")
            .case("qux")
            .create()
            .flatMap
        { bar in
            database.schema("foos")
                .field("id", .uuid, .identifier(auto: false))
                .field("bar", bar, .required)
                .field("baz", bar)
                .create()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete().flatMap {
            database.enum("bar").delete()
        }
    }
}

private struct BarAddQuzAndQuzzMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("bar")
            .case("quz")
            .case("quzz")
            .update()
            .flatMap
        { bar in
            database.schema("foos")
                .updateField("bar", bar)
                .updateField("baz", bar)
                .update()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.enum("bar")
            .deleteCase("quuz")
            .update()
            .flatMap
        { bar in
            database.schema("foos")
                .updateField("bar", bar)
                .updateField("baz", bar)
                .update()
        }
    }
}


private enum Animal: UInt8, Codable {
    case dog, cat
}

private final class Pet: Model {
    static let schema = "pets"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "type")
    var type: Animal

    init() { }

    init(id: IDValue? = nil, type: Animal) {
        self.id = id
        self.type = type
    }
}


private struct PetMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("pets")
            .field("id", .uuid, .identifier(auto: false))
            .field("type", .uint8, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("pets").delete()
    }
}

private final class Flags: Model {
    static let schema = "flags"
    
    @ID(key: .id)
    var id: UUID?
    
    @Boolean(key: "inquired")
    var inquired: Bool
    
    @Boolean(key: "required", format: .integer)
    var required: Bool

    @Boolean(key: "desired", format: .trueFalse)
    var desired: Bool
    
    @OptionalBoolean(key: "expired")
    var expired: Bool?

    @OptionalBoolean(key: "inspired", format: .integer)
    var inspired: Bool?

    @OptionalBoolean(key: "retired", format: .trueFalse)
    var retired: Bool?
    
    init() {}
    
    init(id: IDValue? = nil, inquired: Bool, required: Bool, desired: Bool, expired: Bool? = nil, inspired: Bool? = nil, retired: Bool? = nil) {
        self.id = id
        self.inquired = inquired
        self.required = required
        self.desired = desired
        self.expired = expired
        self.inspired = inspired
        self.retired = retired
    }
}

private final class RawFlags: Model {
    static let schema = "flags"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "inquired") var inquired: Bool
    @Field(key: "required") var required: Int
    @Field(key: "desired") var desired: String
    @OptionalField(key: "expired") var expired: Bool?
    @OptionalField(key: "inspired") var inspired: Int?
    @OptionalField(key: "retired") var retired: String?
    
    init() {}
}

private struct FlagsMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Flags.schema)
            .field(.id, .uuid, .identifier(auto: false), .required)
            .field("inquired", .bool, .required)
            .field("required", .int, .required)
            .field("desired", .string, .required)
            .field("expired", .bool)
            .field("inspired", .int)
            .field("retired", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Flags.schema)
            .delete()
    }
}
