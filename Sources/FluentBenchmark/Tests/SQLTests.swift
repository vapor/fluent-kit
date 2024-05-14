import FluentKit
import Foundation
import NIOCore
import NIOPosix
import XCTest
import SQLKit
import SQLKitBenchmark

extension FluentBenchmarker {
    public func testSQL() throws {
        guard let sql = self.database as? any SQLDatabase else {
            return
        }
        try self.testSQL_rawDecode(sql)
        try MultiThreadedEventLoopGroup.singleton.any().makeFutureWithTask {
            try await SQLBenchmarker(on: sql).runAllTests()
        }.wait()
    }

    private func testSQL_rawDecode(_ sql: any SQLDatabase) throws {
        try self.runTest(#function, [
            UserMigration()
        ]) {
            let tanner = User(firstName: "Tanner", lastName: "Nelson", parentID: UUID())
            try tanner.create(on: self.database).wait()

            // test db.first(decoding:)
            do {
                let user = try sql.raw("SELECT * FROM users").first(decodingFluent: User.self).wait()
                XCTAssertNotNil(user)
                if let user = user {
                    XCTAssertEqual(user.id, tanner.id)
                    XCTAssertEqual(user.firstName, tanner.firstName)
                    XCTAssertEqual(user.lastName, tanner.lastName)
                    XCTAssertEqual(user.$parent.id, tanner.$parent.id)
                }
            }

            // test db.all(decoding:)
            do {
                let users = try sql.raw("SELECT * FROM users").all(decodingFluent: User.self).wait()
                XCTAssertEqual(users.count, 1)
                if let user = users.first {
                    XCTAssertEqual(user.id, tanner.id)
                    XCTAssertEqual(user.firstName, tanner.firstName)
                    XCTAssertEqual(user.lastName, tanner.lastName)
                    XCTAssertEqual(user.$parent.id, tanner.$parent.id)
                }
            }

            // test row.decode()
            do {
                let users = try sql.raw("SELECT * FROM users").all().wait().map {
                    try $0.decode(fluentModel: User.self)
                }
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
}


private final class User: Model, @unchecked Sendable {
    static let schema = "users"

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
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("parent_id", .uuid)
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

