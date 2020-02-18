extension FluentBenchmarker {
    public func testUInt8BackedEnum() throws {
        try runTest(#function, [
            FooMigration()
        ]) {
            let foo = Foo(bar: .baz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
        }
    }
}

private enum Bar: UInt8, Codable {
    case baz, qux
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "bar")
    var bar: Bar

    init() { }

    init(id: IDValue? = nil, bar: Bar) {
        self.id = id
        self.bar = bar
    }
}


private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .uint8, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
