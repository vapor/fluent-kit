extension FluentBenchmarker {
    public func testUUIDModel() throws {
        final class User: Model {
            static let schema = "users"

            @ID(key: FluentBenchmarker.idKey)
            var id: UUID?

            @Field(key: "name")
            var name: String

            init() { }
            init(id: UUID? = nil, name: String) {
                self.id = id
                self.name = name
            }
        }

        struct UserMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users")
                    .field("id", .uuid, .identifier(auto: false))
                    .field("name", .string, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users").delete()
            }
        }

        try self.runTest(#function, [
            UserMigration(),
        ]) {
            try User(name: "Vapor")
                .save(on: self.database).wait()
            let count = try User.query(on: self.database).count().wait()
            XCTAssertEqual(count, 1, "User did not save")
        }
    }

    public func testNewModelDecode() throws {
        final class Todo: Model {
            static let schema = "todos"

            @ID(key: FluentBenchmarker.idKey)
            var id: UUID?

            @Field(key: "title")
            var title: String

            init() { }
            init(id: UUID? = nil, title: String) {
                self.id = id
                self.title = title
            }
        }

        struct TodoMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("todos")
                    .field("id", .uuid, .identifier(auto: false))
                    .field("title", .string, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("todos").delete()
            }
        }

        try self.runTest(#function, [
            TodoMigration(),
        ]) {
            let todo = """
            {"title": "Finish Vapor 4"}
            """
            try JSONDecoder().decode(Todo.self, from: todo.data(using: .utf8)!)
                .save(on: self.database).wait()
            guard try Todo.query(on: self.database).count().wait() == 1 else {
                XCTFail("Todo did not save")
                return
            }
        }
    }

    public func testNullifyField() throws {
        try runTest(#function, [
            FooMigration(),
        ]) {
            let foo = Foo(bar: "test")
            try foo.save(on: self.database).wait()
            guard foo.bar != nil else {
                XCTFail("unexpected nil value")
                return
            }
            foo.bar = nil
            try foo.save(on: self.database).wait()
            guard foo.bar == nil else {
                XCTFail("unexpected non-nil value")
                return
            }

            guard let fetched = try Foo.query(on: self.database)
                .filter(\.$id == foo.id!)
                .first().wait()
            else {
                XCTFail("no model returned")
                return
            }
            guard fetched.bar == nil else {
                XCTFail("unexpected non-nil value")
                return
            }
        }
    }

    public func testIdentifierGeneration() throws {
        try runTest(#function, [
            GalaxyMigration(),
        ]) {
            let galaxy = Galaxy(name: "Milky Way")
            guard galaxy.id == nil else {
                XCTFail("id should not be set")
                return
            }
            try galaxy.save(on: self.database).wait()

            let a = Galaxy(name: "A")
            let b = Galaxy(name: "B")
            let c = Galaxy(name: "C")
            try a.save(on: self.database).wait()
            try b.save(on: self.database).wait()
            try c.save(on: self.database).wait()
            guard a.id != b.id && b.id != c.id && a.id != c.id else {
                XCTFail("ids should not be equal")
                return
            }
        }
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: FluentBenchmarker.idKey)
    var id: UUID?

    @Field(key: "bar")
    var bar: String?

    init() { }

    init(id: IDValue? = nil, bar: String?) {
        self.id = id
        self.bar = bar
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("foos").delete()
    }
}
