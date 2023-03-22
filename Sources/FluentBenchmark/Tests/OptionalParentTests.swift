import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testOptionalParent() throws {
        try runTest(#function, [
            UserMigration()
        ]) {
            // seed
            do {
                let swift = User(
                    name: "Swift",
                    pet: .init(name: "Foo", type: .dog),
                    bestFriend: nil
                )
                try swift.save(on: self.database).wait()
                let vapor = User(
                    name: "Vapor",
                    pet: .init(name: "Bar", type: .cat),
                    bestFriend: swift
                )
                try vapor.save(on: self.database).wait()
            }

            // test fetch user with nil parent
            do {
                let swift = try User.query(on: self.database)
                    .filter(\.$name == "Swift")
                    .first().wait()!
                try XCTAssertNil(swift.$bestFriend.get(on: self.database).wait())
            }
            // test fetch user with non-nil parent
            do {
                let swift = try User.query(on: self.database)
                    .filter(\.$name == "Vapor")
                    .first().wait()!
                try XCTAssertNotNil(swift.$bestFriend.get(on: self.database).wait())
            }

            // test
            let users = try User.query(on: self.database)
                .with(\.$bestFriend)
                .with(\.$friends)
                .all().wait()
            for user in users {
                switch user.name {
                case "Swift":
                    XCTAssertEqual(user.bestFriend?.name, nil)
                    XCTAssertEqual(user.friends.count, 1)
                case "Vapor":
                    XCTAssertEqual(user.bestFriend?.name, "Swift")
                    XCTAssertEqual(user.friends.count, 0)
                default:
                    XCTFail("unexpected name: \(user.name)")
                }
            }

            // test query with no ids
            // https://github.com/vapor/fluent-kit/issues/85
            let users2 = try User.query(on: self.database)
                .with(\.$bestFriend)
                .filter(\.$bestFriend.$id == nil)
                .all().wait()
            XCTAssertEqual(users2.count, 1)
            XCTAssert(users2.first?.bestFriend == nil)
            
            // Test deleted OptionalParent
            try User.query(on: self.database).filter(\.$name == "Swift").delete().wait()
            
            let users3 = try User.query(on: self.database)
                .with(\.$bestFriend, withDeleted: true)
                .all().wait()
            XCTAssertEqual(users3.first?.bestFriend?.name, "Swift")
            
            XCTAssertThrowsError(try User.query(on: self.database)
                .with(\.$bestFriend)
                .all().wait()
            ) { error in
                guard case let .missingParent(from, to, key, _) = error as? FluentError else {
                    return XCTFail("Unexpected error \(error) thrown")
                }
                XCTAssertEqual(from, "User")
                XCTAssertEqual(to, "User")
                XCTAssertEqual(key, "bf_id")
            }
        }
    }
}

private final class User: Model {
    struct Pet: Codable {
        enum Animal: String, Codable {
            case cat, dog
        }
        var name: String
        var type: Animal
    }
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "pet")
    var pet: Pet

    @OptionalParent(key: "bf_id")
    var bestFriend: User?

    @Children(for: \.$bestFriend)
    var friends: [User]
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() { }

    init(id: IDValue? = nil, name: String, pet: Pet, bestFriend: User? = nil) {
        self.id = id
        self.name = name
        self.pet = pet
        self.$bestFriend.id = bestFriend?.id
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("pet", .json, .required)
            .field("bf_id", .uuid)
            .field("deleted_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}


private struct UserSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let tanner = User(name: "Tanner", pet: .init(name: "Ziz", type: .cat))
        let logan = User(name: "Logan", pet: .init(name: "Runa", type: .dog))
        return logan.save(on: database)
            .and(tanner.save(on: database))
            .map { _ in }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
