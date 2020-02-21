extension FluentBenchmarker {
    public func testEnum() throws {
        try self.testEnum_basic()
        try self.testEnum_addCase()
        try self.testEnum_raw()
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
