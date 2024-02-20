import FluentKit
import Foundation
import NIOCore
import XCTest
import SQLKit

extension FluentBenchmarker {
    public func testModel() throws {
        try self.testModel_uuid()
        try self.testModel_decode()
        try self.testModel_nullField()
        try self.testModel_nullField_batchCreate()
        try self.testModel_idGeneration()
        try self.testModel_jsonColumn()
        try self.testModel_hasChanges()
        try self.testModel_outputError()
        if self.database is SQLDatabase {
            // Broken in Mongo at this time
            try self.testModel_useOfFieldsWithoutGroup()
        }
    }

    private func testModel_uuid() throws {
        try self.runTest(#function, [
            UserMigration(),
        ]) {
            try User(name: "Vapor")
                .save(on: self.database).wait()
            let count = try User.query(on: self.database).count().wait()
            XCTAssertEqual(count, 1, "User did not save")
        }
    }

    private func testModel_decode() throws {
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

    private func testModel_nullField() throws {
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

            // test find + update with nil value works
            guard let found = try Foo.find(foo.id, on: self.database).wait() else {
                XCTFail("unexpected nil value")
                return
            }
            try found.update(on: self.database).wait()

            let all = try Foo.query(on: self.database)
                .filter(\.$bar == nil)
                .all().wait()
            XCTAssertEqual(all.count, 1)

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

    private func testModel_nullField_batchCreate() throws {
        try runTest(#function, [
            FooMigration(),
        ]) {
            let a = Foo(bar: "test")
            let b = Foo(bar: nil)
            try [a, b].create(on: self.database).wait()
        }
    }

    private func testModel_idGeneration() throws {
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

    private func testModel_jsonColumn() throws {
        try runTest(#function, [
            BarMigration(),
        ]) {
            let bar = Bar(baz: .init(quux: "test"))
            try bar.save(on: self.database).wait()

            let fetched = try Bar.find(bar.id, on: self.database).wait()
            XCTAssertEqual(fetched?.baz.quux, "test")

            if self.database is SQLDatabase {
                let bars = try Bar.query(on: self.database)
                    .filter(.sql(json: "baz", "quux"), .equal, .bind("test"))
                    .all()
                    .wait()
                XCTAssertEqual(bars.count, 1)
            }
        }
    }

    private func testModel_hasChanges() throws {
        try runTest(#function, [
            FooMigration(),
        ]) {
            // Test create
            let foo = Foo(bar: "test")
            XCTAssertTrue(foo.hasChanges)
            try foo.save(on: self.database).wait()
            XCTAssertFalse(foo.hasChanges)

            // Test update
            guard let fetched = try Foo.query(on: self.database)
                .filter(\.$id == foo.id!)
                .first().wait()
            else {
                XCTFail("no model returned")
                return
            }
            XCTAssertFalse(fetched.hasChanges)
            fetched.bar = nil
            XCTAssertTrue(fetched.hasChanges)
            try fetched.save(on: self.database).wait()
            XCTAssertFalse(fetched.hasChanges)
        }
    }

    private func testModel_outputError() throws {
        try runTest(#function, []) {
            let foo = Foo()
            do {
                try foo.output(from: BadFooOutput())
            } catch {
                XCTAssert("\(error)".contains("id"))
            }
        }
    }
    
    private func testModel_useOfFieldsWithoutGroup() throws {
        try runTest(#function, []) {
            final class Contained: Fields {
                @Field(key: "something") var something: String
                @Field(key: "another") var another: Int
                init() {}
            }
            final class Enclosure: Model {
                static let schema = "enclosures"
                @ID(custom: .id) var id: Int?
                @Field(key: "primary") var primary: Contained
                @Field(key: "additional") var additional: [Contained]
                init() {}
                
                struct Migration: FluentKit.Migration {
                    func prepare(on database: Database) -> EventLoopFuture<Void> {
                        database.schema(Enclosure.schema)
                            .field(.id, .int, .required, .identifier(auto: true))
                            .field("primary", .json, .required)
                            .field("additional", .array(of: .json), .required)
                            .create()
                    }
                    func revert(on database: Database) -> EventLoopFuture<Void> { database.schema(Enclosure.schema).delete() }
                }
            }
            
            try Enclosure.Migration().prepare(on: self.database).wait()
            
            let enclosure = Enclosure()
            enclosure.primary = .init()
            enclosure.primary.something = ""
            enclosure.primary.another = 0
            enclosure.additional = []
            try enclosure.save(on: self.database).wait()
            
            try! Enclosure.Migration().revert(on: self.database).wait()
        }
    }
}

struct BadFooOutput: DatabaseOutput {
    func schema(_ schema: String) -> DatabaseOutput {
        self
    }

    func nested(_ key: FieldKey) throws -> DatabaseOutput {
        self
    }

    func contains(_ key: FieldKey) -> Bool {
        true
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        false
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T : Decodable
    {
        throw DecodingError.typeMismatch(T.self, .init(
            codingPath: [],
            debugDescription: "Failed to decode",
            underlyingError: nil
        ))
    }

    var description: String {
        "bad foo output"
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: .id)
    var id: UUID?

    @OptionalField(key: "bar")
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

private final class User: Model {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    init() { }
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

private final class Todo: Model {
    static let schema = "todos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    init() { }
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

private struct TodoMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("todos")
            .field("id", .uuid, .identifier(auto: false))
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("todos").delete()
    }
}

private final class Bar: Model {
    static let schema = "bars"

    @ID
    var id: UUID?

    struct Baz: Codable {
        var quux: String
    }

    @Field(key: "baz")
    var baz: Baz

    init() { }

    init(id: IDValue? = nil, baz: Baz) {
        self.id = id
        self.baz = baz
    }
}

private struct BarMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("bars")
            .field("id", .uuid, .identifier(auto: false))
            .field("baz", .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("bars").delete()
    }
}
