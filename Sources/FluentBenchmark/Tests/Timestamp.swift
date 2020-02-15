extension FluentBenchmarker {
    public func testTimestampable() throws {
        final class User: Model {
            static let schema = "users"

            @ID(key: "id")
            var id: Int?

            @Field(key: "name")
            var name: String

            @Timestamp(key: "created_at", on: .create)
            var createdAt: Date?

            @Timestamp(key: "updated_at", on: .update)
            var updatedAt: Date?

            init() { }
            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
                self.createdAt = nil
                self.updatedAt = nil
            }
        }

        struct UserMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users")
                    .field("id", .int, .identifier(auto: true))
                    .field("name", .string, .required)
                    .field("created_at", .datetime)
                    .field("updated_at", .datetime)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users").delete()
            }
        }


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
}
