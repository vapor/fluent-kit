extension FluentBenchmarker {
    public func testEnums() throws {
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
        }
    }

    public func testAddEnumCase() throws {
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
