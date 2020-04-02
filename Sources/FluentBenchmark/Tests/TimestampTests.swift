@testable import class FluentKit.QueryBuilder

extension FluentBenchmarker {
    public func testTimestamp() throws {
        try self.testTimestamp_touch()
        try self.testTimestamp_ISO8601()
    }

    public func testTimestamp_touch() throws {
        try runTest(#function, [
            UserMigration(),
        ]) {
            let user = User(name: "A")
            XCTAssertEqual(user.createdAt, nil)
            XCTAssertEqual(user.updatedAt, nil)
            try user.create(on: self.database).wait()
            XCTAssertNotNil(user.createdAt)
            XCTAssertNotNil(user.updatedAt)
            XCTAssertEqual(user.updatedAt, user.createdAt)
            user.name = "B"
            try user.save(on: self.database).wait()
            XCTAssertNotNil(user.createdAt)
            XCTAssertNotNil(user.updatedAt)
            XCTAssertNotEqual(user.updatedAt, user.createdAt)
        }
    }

    public func testTimestamp_ISO8601() throws {
        try runTest(#function, [
            EventMigration(),
        ]) {
            let event = Event(name: "ServerSide.swift")
            try event.create(on: self.database).wait()

            event.name = "Vapor Bay"
            try event.save(on: self.database).wait()

            let formatter = ISO8601DateFormatter()
            let createdAt = try formatter.string(from: XCTUnwrap(event.createdAt))
            let updatedAt = try formatter.string(from: XCTUnwrap(event.updatedAt))

            try Event.query(on: self.database).run({ output in
                do {
                    let schema = output.schema("events")
                    let createdAtField = try schema.decode(event.$createdAt.field.key, as: String.self)
                    let updatedAtField = try schema.decode(event.$updatedAt.field.key, as: String.self)
                    XCTAssertEqual(createdAtField, createdAt)
                    XCTAssertEqual(updatedAtField, updatedAt)
                } catch let error {
                    XCTFail("Timestamp decoding from database output failed with error: \(error)")
                }
            }).wait()

            try event.delete(on: self.database).wait()
            try XCTAssertEqual(Event.query(on: self.database).all().wait().count, 0)
        }
    }
}

private final class User: Model {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }
    
    init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
        self.createdAt = nil
        self.updatedAt = nil
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}


private final class Event: Model {
    static let schema = "events"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .update, format: .iso8601)
    var deletedAt: Date?

    init() { }

    init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
        self.createdAt = nil
        self.updatedAt = nil
        self.deletedAt = nil
    }
}

private struct EventMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("events")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("created_at", .string)
            .field("updated_at", .string)
            .field("deleted_at", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("events").delete()
    }
}
