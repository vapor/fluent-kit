extension FluentBenchmarker {
    public func testSet() throws {
        try self.runTest(#function, [
            FooMigration(),
        ]) {
            let foo = Foo(bar: ["a", "b", "c"])
            try foo.create(on: self.database).wait()
            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, foo.bar)
        }
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: "id")
    var id: UUID?

    @Field(key: "bar")
    var bar: Set<String>

    init() { }

    init(id: IDValue? = nil, bar: Set<String>) {
        self.id = id
        self.bar = bar
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
