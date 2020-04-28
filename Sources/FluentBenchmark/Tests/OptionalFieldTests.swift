import FluentSQL

extension FluentBenchmarker {
    public func testOptionalField() throws {
        try self.testOptionalField_main()
    }

    private func testOptionalField_main() throws {
        try runTest(#function, [
            FooMigration(),
        ]) {
            try Foo(a: "a", b: "b", c: "c")
                .save(on: self.database).wait()
            try Foo(a: nil, b: "b", c: "c")
                .save(on: self.database).wait()
            try Foo(a: "a", b: nil, c: "c")
                .save(on: self.database).wait()
            try Foo(a: nil, b: nil, c: "c")
                .save(on: self.database).wait()

            do {
                let foos = try Foo.query(on: self.database)
                    .filter(\.$a == nil)
                    .filter(\.$b != nil)
                    .all()
                    .wait()
                XCTAssertEqual(foos.count, 1)
            }
            do {
                let foos = try Foo.query(on: self.database)
                    .filter(\.$a != nil)
                    .filter(\.$b == nil)
                    .all()
                    .wait()
                XCTAssertEqual(foos.count, 1)
            }
            do {
                let foos = try Foo.query(on: self.database)
                    .filter(\.$a == nil)
                    .filter(\.$b == nil)
                    .all()
                    .wait()
                XCTAssertEqual(foos.count, 1)
            }
            do {
                let foos = try Foo.query(on: self.database)
                    .filter(\.$a != nil)
                    .filter(\.$b != nil)
                    .all()
                    .wait()
                XCTAssertEqual(foos.count, 1)
            }
        }
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "a")
    var a: String?

    @OptionalField(key: "b")
    var b: String?

    @Field(key: "c")
    var c: String

    init() { }

    init(id: IDValue? = nil, a: String?, b: String?, c: String) {
        self.id = id
        self.a = a
        self.b = b
        self.c = c
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .id()
            .field("a", .string)
            .field("b", .string)
            .field("c", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
