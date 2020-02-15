extension FluentBenchmarker {
    public func testSameChildrenFromKey() throws {
        final class Foo: Model {
            static let schema = "foos"

            struct _Migration: Migration {
                func prepare(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos")
                        .field("id", .int, .identifier(auto: true))
                        .field("name", .string, .required)
                        .create()
                }

                func revert(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos").delete()
                }
            }

            @ID(key: "id")
            var id: Int?

            @Field(key: "name")
            var name: String

            @Children(for: \.$foo)
            var bars: [Bar]

            @Children(for: \.$foo)
            var bazs: [Baz]

            init() { }

            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
            }
        }

        final class Bar: Model {
            static let schema = "bars"

            struct _Migration: Migration {
                func prepare(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("bars")
                        .field("id", .int, .identifier(auto: true))
                        .field("bar", .int, .required)
                        .field("foo_id", .int, .required)
                        .create()
                }

                func revert(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("bars").delete()
                }
            }

            @ID(key: "id")
            var id: Int?

            @Field(key: "bar")
            var bar: Int

            @Parent(key: "foo_id")
            var foo: Foo

            init() { }

            init(id: Int? = nil, bar: Int, fooID: Int) {
                self.id = id
                self.bar = bar
                self.$foo.id = fooID
            }
        }

        final class Baz: Model {
            static let schema = "bazs"

            struct _Migration: Migration {
                func prepare(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("bazs")
                        .field("id", .int, .identifier(auto: true))
                        .field("baz", .double, .required)
                        .field("foo_id", .int, .required)
                        .create()
                }

                func revert(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("bazs").delete()
                }
            }

            @ID(key: "id")
            var id: Int?

            @Field(key: "baz")
            var baz: Double

            @Parent(key: "foo_id")
            var foo: Foo

            init() { }

            init(id: Int? = nil, baz: Double, fooID: Int) {
                self.id = id
                self.baz = baz
                self.$foo.id = fooID
            }
        }
        try runTest(#function, [
            Foo._Migration(),
            Bar._Migration(),
            Baz._Migration()
        ]) {
            let foo = Foo(name: "a")
            try foo.save(on: self.database).wait()
            let bar = Bar(bar: 42, fooID: foo.id!)
            try bar.save(on: self.database).wait()
            let baz = Baz(baz: 3.14, fooID: foo.id!)
            try baz.save(on: self.database).wait()

            let foos = try Foo.query(on: self.database)
                .with(\.$bars)
                .with(\.$bazs)
                .all().wait()

            for foo in foos {
                XCTAssertEqual(foo.bars[0].bar, 42)
                XCTAssertEqual(foo.bazs[0].baz, 3.14)
            }
        }
    }

}
