extension FluentBenchmarker {
    public func testUInt8BackedEnum() throws {
        enum Bar: UInt8, Codable {
            case baz, qux
        }
        final class Foo: Model {
            static let schema = "foos"

            struct _Migration: Migration {
                func prepare(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos")
                        .field("id", .int, .identifier(auto: true))
                        .field("bar", .uint8, .required)
                        .create()
                }

                func revert(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos").delete()
                }
            }

            @ID(key: "id")
            var id: Int?

            @Field(key: "bar")
            var bar: Bar

            init() { }

            init(id: Int? = nil, bar: Bar) {
                self.id = id
                self.bar = bar
            }
        }
        try runTest(#function, [
            Foo._Migration()
        ]) {
            let foo = Foo(bar: .baz)
            try foo.save(on: self.database).wait()

            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, .baz)
        }
    }
}
