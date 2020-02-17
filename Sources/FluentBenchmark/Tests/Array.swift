extension FluentBenchmarker {
    public func testArray() throws {
        struct Qux: Codable {
            var foo: String
        }

        final class Foo: Model {
            static let schema = "foos"

            struct _Migration: Migration {
                func prepare(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos")
                        .field("id", .uuid, .identifier(auto: false))
                        .field("bar", .array(of: .int), .required)
                        .field("baz", .array(of: .string))
                        .field("qux", .array(of: .json), .required)
                        .create()
                }

                func revert(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos").delete()
                }
            }

            @ID(key: FluentBenchmarker.idKey)
            var id: UUID?

            @Field(key: "bar")
            var bar: [Int]

            @Field(key: "baz")
            var baz: [String]?

            @Field(key: "qux")
            var qux: [Qux]

            init() { }

            init(id: UUID? = nil, bar: [Int], baz: [String]?, qux: [Qux]) {
                self.id = id
                self.bar = bar
                self.baz = baz
                self.qux = qux
            }
        }

        try runTest(#function, [
            Foo._Migration(),
        ]) {
            let new = Foo(
                bar: [1, 2, 3],
                baz: ["4", "5", "6"],
                qux: [.init(foo: "7"), .init(foo: "8"), .init(foo: "9")]
            )
            try new.create(on: self.database).wait()

            guard let fetched = try Foo.find(new.id, on: self.database).wait() else {
                XCTFail("foo didnt save")
                return
            }
            XCTAssertEqual(fetched.bar, [1, 2, 3])
            XCTAssertEqual(fetched.baz, ["4", "5", "6"])
            XCTAssertEqual(fetched.qux.map { $0.foo }, ["7", "8", "9"])
        }
    }
}
