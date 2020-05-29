import class FluentKit.QueryBuilder

extension FluentBenchmarker {
    public func testTimestamp() throws {
        try self.testTimestamp_touch()
        try self.testTimestamp_ISO8601()
        try self.testTimestamp_createOnUpdate()
        try self.testTimestamp_createOnBulkCreate()
        try self.testTimestamp_createOnBulkUpdate()
        try self.testTimestamp_updateNoChanges()
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
            formatter.formatOptions.insert(.withFractionalSeconds)
            let createdAt = formatter.string(from: event.createdAt!)
            let updatedAt = formatter.string(from: event.updatedAt!)
            try Event.query(on: self.database).run({ output in
                do {
                    let schema = output.schema("events")
                    let createdAtField = try schema.decode(event.$createdAt.$timestamp.key, as: String.self)
                    let updatedAtField = try schema.decode(event.$updatedAt.$timestamp.key, as: String.self)
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
    
    public func testTimestamp_createOnUpdate() throws {
        try runTest(#function, [
            EventMigration()
        ]) {
            let event = Event(name: "C")
            try event.create(on: self.database).wait()
            XCTAssertNotNil(event.createdAt)
            XCTAssertNotNil(event.updatedAt)
            XCTAssertEqual(event.createdAt, event.updatedAt)
            
            Thread.sleep(forTimeInterval: 0.001) // ensure update timestamp with millisecond precision increments

            let storedEvent = try Event.find(event.id, on: self.database).wait()
            XCTAssertNotNil(storedEvent)
            XCTAssertNotNil(storedEvent?.createdAt)
            XCTAssertNotNil(storedEvent?.updatedAt)
            XCTAssertEqual(storedEvent?.createdAt, event.createdAt)
        }
    }
    
    public func testTimestamp_createOnBulkCreate() throws {
        try runTest(#function, [
            UserMigration(),
        ]) {
            let userOne = User(name: "A")
            let userTwo = User(name: "B")
            XCTAssertEqual(userOne.createdAt, nil)
            XCTAssertEqual(userOne.updatedAt, nil)
            XCTAssertEqual(userTwo.createdAt, nil)
            XCTAssertEqual(userTwo.updatedAt, nil)
            try [userOne, userTwo].create(on: self.database).wait()
            XCTAssertNotNil(userOne.createdAt)
            XCTAssertNotNil(userOne.updatedAt)
            XCTAssertEqual(userOne.updatedAt, userOne.createdAt)
            XCTAssertNotNil(userTwo.createdAt)
            XCTAssertNotNil(userTwo.updatedAt)
            XCTAssertEqual(userTwo.updatedAt, userTwo.createdAt)
        }
    }
    
    public func testTimestamp_createOnBulkUpdate() throws {
        try runTest(#function, [
            UserMigration(),
        ]) {
            let userOne = User(name: "A")
            let userTwo = User(name: "B")
            XCTAssertEqual(userOne.createdAt, nil)
            XCTAssertEqual(userOne.updatedAt, nil)
            XCTAssertEqual(userTwo.createdAt, nil)
            XCTAssertEqual(userTwo.updatedAt, nil)
            try [userOne, userTwo].create(on: self.database).wait()
            
            let originalOne = userOne.updatedAt
            let originalTwo = userTwo.updatedAt
            
            Thread.sleep(forTimeInterval: 1)
            
            try User.query(on: self.database).set(\.$name, to: "C").update().wait()
            
            XCTAssertNotEqual(try User.find(userOne.id, on: self.database).wait()!.updatedAt!.timeIntervalSinceNow, originalOne!.timeIntervalSinceNow)
            XCTAssertNotEqual(try User.find(userTwo.id, on: self.database).wait()!.updatedAt!.timeIntervalSinceNow, originalTwo!.timeIntervalSinceNow)
        }
    }

    public func testTimestamp_updateNoChanges() throws {
        try runTest(#function, [
            EventMigration()
        ]) {
            let event = Event(name: "C")
            try event.create(on: self.database).wait()
            let updatedAtPreSave = event.updatedAt

            XCTAssertFalse(event.hasChanges)
            Thread.sleep(forTimeInterval: 0.001) // ensure update timestamp with millisecond precision increments
            try event.save(on: self.database).wait()

            let storedEvent = try Event.find(event.id, on: self.database).wait()
            XCTAssertEqual(storedEvent?.updatedAt, updatedAtPreSave)
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

    @Timestamp(key: "created_at", on: .create, format: .iso8601(withMilliseconds: true))
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601(withMilliseconds: true))
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete, format: .iso8601(withMilliseconds: true))
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
