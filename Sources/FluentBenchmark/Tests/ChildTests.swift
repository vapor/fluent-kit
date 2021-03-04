extension FluentBenchmarker {
    public func testChild() throws {
        try self.testChild_with()
    }

    private func testChild_with() throws {
        try self.runTest(#function, [
            FooMigration(),
            BarMigration(),
            BazMigration()
        ]) {
            let foo = Foo(name: "a")
            try foo.save(on: self.database).wait()
            let bar = Bar(bar: 42, fooID: foo.id!)
            try bar.save(on: self.database).wait()
            let baz = Baz(baz: 3.14)
            try baz.save(on: self.database).wait()
            
            // Test relationship @Parent - @OptionalChild
            // query(on: Parent)
            let foos = try Foo.query(on: self.database)
                .with(\.$bar)
                .with(\.$baz)
                .all().wait()

            for foo in foos {
                // Child `bar` is eager loaded
                XCTAssertEqual(foo.bar?.bar, 42)
                // Child `baz` isn't eager loaded
                XCTAssertNil(foo.baz?.baz)
            }
            
            // Test relationship @Parent - @OptionalChild
            // query(on: Child)
            let bars = try Bar.query(on: self.database)
                .with(\.$foo)
                .all().wait()
            
            for bar in bars {
                XCTAssertEqual(bar.foo.name, "a")
            }
            
            // Test relationship @OptionalParent - @OptionalChild
            // query(on: Child)
            let bazs = try Baz.query(on: self.database)
                .with(\.$foo)
                .all().wait()
            
            for baz in bazs {
                // test with missing parent
                XCTAssertNil(baz.foo?.name)
            }
            
            baz.$foo.id = foo.id
            try baz.save(on: self.database).wait()
            
            let updatedBazs = try Baz.query(on: self.database)
                .with(\.$foo)
                .all().wait()
            
            for updatedBaz in updatedBazs {
                // test with valid parent
                XCTAssertEqual(updatedBaz.foo?.name, "a")
            }
        }
    }
}


private final class Foo: Model {
    static let schema = "foos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @OptionalChild(for: \.$foo)
    var bar: Bar?

    @OptionalChild(for: \.$foo)
    var baz: Baz?

    init() { }

    init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}

private final class Bar: Model {
    static let schema = "bars"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "bar")
    var bar: Int

    @Parent(key: "foo_id")
    var foo: Foo

    init() { }

    init(id: IDValue? = nil, bar: Int, fooID: Foo.IDValue) {
        self.id = id
        self.bar = bar
        self.$foo.id = fooID
    }
}

private struct BarMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bars")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .int, .required)
            .field("foo_id", .uuid, .required)
            .unique(on: "foo_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bars").delete()
    }
}

private final class Baz: Model {
    static let schema = "bazs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "baz")
    var baz: Double

    @OptionalParent(key: "foo_id")
    var foo: Foo?

    init() { }

    init(id: IDValue? = nil, baz: Double, fooID: Foo.IDValue? = nil) {
        self.id = id
        self.baz = baz
        self.$foo.id = fooID
    }
}

private struct BazMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bazs")
            .field("id", .uuid, .identifier(auto: false))
            .field("baz", .double, .required)
            .field("foo_id", .uuid)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bazs").delete()
    }
}
