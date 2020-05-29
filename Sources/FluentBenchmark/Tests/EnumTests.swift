extension FluentBenchmarker {
    public func testEnum() throws {
        try self.testEnum_basic()
        try self.testEnum_addCase()
        try self.testEnum_raw()
        try self.testEnum_queryFound()
        try self.testEnum_queryMissing()
        try self.testEnum_decode()
    }

    private func testEnum_basic() throws {
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz, baz: .qux)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
            XCTAssertEqual(fetched?.baz, .qux)
        }
    }

    private func testEnum_addCase() throws {
        try self.runTest(#function, [
            FooMigration(),
            BarAddQuuzMigration()
        ]) {
            let foo = Foo(bar: .baz, baz: .qux)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
            XCTAssertEqual(fetched?.baz, .qux)
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
}

private enum Bar: String, Codable {
    case baz, qux, quuz
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

private struct BarAddQuuzMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("bar")
            .case("quuz")
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
