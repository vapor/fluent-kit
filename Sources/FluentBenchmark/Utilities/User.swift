import FluentKit

final class User: Model {
    struct Pet: Codable {
        enum Animal: String, Codable {
            case cat, dog
        }
        var name: String
        var type: Animal
    }
    static let schema = "users"
    
    @ID(key: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Field(key: "pet")
    var pet: Pet

    @OptionalParent(key: "bf_id")
    var bestFriend: User?

    @Children(for: \.$bestFriend)
    var friends: [User]

    init() { }

    init(id: Int? = nil, name: String, pet: Pet, bestFriend: User? = nil) {
        self.id = id
        self.name = name
        self.pet = pet
        self.$bestFriend.id = bestFriend?.id
    }
}

struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("pet", .json, .required)
            .field("bf_id", .int)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}


final class UserSeed: Migration {
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
