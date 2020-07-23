import FluentSQL

extension FluentBenchmarker {
    public func testSQL() throws {
        guard let sql = self.database as? SQLDatabase else {
            return
        }
        try self.testSQL_rawDecode(sql)
    }

    private func testSQL_rawDecode(_ sql: SQLDatabase) throws {
        try self.runTest(#function, [
            UserMigration()
        ]) {
             let tanner = User(firstName: "Tanner", lastName: "Nelson", parentID: UUID())
             try tanner.create(on: self.database).wait()
             print(tanner)

             let users = try sql.raw("SELECT * FROM users_sql").all(decoding: User.self).wait()
             XCTAssertEqual(users.count, 1)
             if let user = users.first {
                XCTAssertEqual(user.id, tanner.id)
                XCTAssertEqual(user.firstName, tanner.firstName)
                XCTAssertEqual(user.lastName, tanner.lastName)
                XCTAssertEqual(user.$parent.id, tanner.$parent.id)
             }
        }
    }
}


private final class User: Model {
    static let schema = "users_sql"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @OptionalParent(key: "parent_id")
    var parent: User?

    init() { }

    init(
        id: UUID? = nil, 
        firstName: String,
        lastName: String,
        parentID: UUID? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.$parent.id = parentID
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("parent_id", .uuid)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeSucceededFuture(())
    }
}

