extension FluentBenchmarker {
    // https://github.com/vapor/fluent-kit/issues/132
    public func testCustomID() throws {
        try runTest(#function, [
            CreateFoo(),
        ]) {
            let random = Foo()
            try random.save(on: self.database).wait()
            XCTAssertNotNil(random.id)

            let uuid = UUID()
            let custom = Foo(id: uuid)
            try custom.save(on: self.database).wait()
            XCTAssertEqual(custom.id, uuid)
        }
    }
}


private final class Foo: Model {
    static let schema = "foos"

    @ID(key: FluentBenchmarker.idKey)
    var id: UUID?

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}

private struct CreateFoo: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
