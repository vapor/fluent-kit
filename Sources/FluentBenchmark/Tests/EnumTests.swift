extension FluentBenchmarker {
    public func testEnum() throws {
        try self.testEnum_basic()
        try self.testEnum_addCase()
        try self.testEnum_raw()
        try self.testEnum_queryFound()
        try self.testEnum_queryMissing()
    }

    private func testEnum_basic() throws {
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
        }
    }

    private func testEnum_addCase() throws {
        try self.runTest(#function, [
            FooMigration(),
            BarAddQuuzMigration()
        ]) {
            let foo = Foo(bar: .baz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
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
            let foo = Foo(bar: .baz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo
                .query(on: self.database)
                .filter(\.$bar == .baz)
                .first()
                .wait()
            XCTAssertEqual(fetched?.bar, .baz)

            // not equal
            let foo2 = Foo(bar: .baz)
            try foo2.save(on: self.database).wait()

            let fetched2 = try Foo
                .query(on: self.database)
                .filter(\.$bar != .qux)
                .first()
                .wait()
            XCTAssertEqual(fetched2?.bar, .baz)

            // in
            let foo3 = Foo(bar: .baz)
            try foo3.save(on: self.database).wait()

            let fetched3 = try Foo
                .query(on: self.database)
                .filter(\.$bar ~~ [.baz, .qux])
                .first()
                .wait()
            XCTAssertEqual(fetched3?.bar, .baz)

            // not in
            let foo4 = Foo(bar: .baz)
            try foo4.save(on: self.database).wait()

            let fetched4 = try Foo
                .query(on: self.database)
                .filter(\.$bar !~ [.qux])
                .first()
                .wait()
            XCTAssertEqual(fetched4?.bar, .baz)
        }
    }

    public func testEnum_queryMissing() throws {
        // equal
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo
                .query(on: self.database)
                .filter(\.$bar == .qux)
                .first()
                .wait()
            XCTAssertNil(fetched)

            // not equal
            let foo2 = Foo(bar: .baz)
            try foo2.save(on: self.database).wait()

            let fetched2 = try Foo
                .query(on: self.database)
                .filter(\.$bar != .baz)
                .first()
                .wait()
            XCTAssertNil(fetched2)

            // in
            let foo3 = Foo(bar: .baz)
            try foo3.save(on: self.database).wait()

            let fetched3 = try Foo
                .query(on: self.database)
                .filter(\.$bar ~~ [.qux])
                .first()
                .wait()
            XCTAssertNil(fetched3)

            // not in
            let foo4 = Foo(bar: .baz)
            try foo4.save(on: self.database).wait()

            let fetched4 = try Foo
                .query(on: self.database)
                .filter(\.$bar !~ [.baz, .qux])
                .first()
                .wait()
            XCTAssertNil(fetched4)
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

    init() { }

    init(id: IDValue? = nil, bar: Bar) {
        self.id = id
        self.bar = bar
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
