extension FluentBenchmarker {
    public func testNonstandardIDKey() throws {
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(baz: "qux")
            try foo.save(on: self.database).wait()
            XCTAssertNotNil(foo.id)
        }
    }

    public func testAutoincrementingID() throws {
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo1 = Foo(baz: "qux")
            try foo1.save(on: self.database).wait()
            XCTAssertNotNil(foo1.id)
            let foo2 = Foo(baz: "qux")
            try foo2.save(on: self.database).wait()
            XCTAssertNotNil(foo2.id)
        }
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: "bar")
    var id: UUID?

    @Field(key: "baz")
    var baz: String

    init() { }

    init(id: IDValue? = nil, baz: String) {
        self.id = id
        self.baz = baz
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("bar", .uuid, .identifier(auto: false))
            .field("baz", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
