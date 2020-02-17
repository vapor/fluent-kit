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
            XCTAssertEqual(foo1.id, 1)
            let foo2 = Foo(baz: "qux")
            try foo2.save(on: self.database).wait()
            XCTAssertEqual(foo2.id, 2)
        }
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: "bar")
    var id: Int?

    @Field(key: "baz")
    var baz: String

    init() { }

    init(id: Int? = nil, baz: String) {
        self.id = id
        self.baz = baz
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("bar", .int, .identifier(auto: true))
            .field("baz", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
