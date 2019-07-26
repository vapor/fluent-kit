import FluentKit

final class User: Model {
    struct Pet: Codable {
        enum Animal: String, Codable {
            case cat, dog
        }
        var name: String
        var type: Animal
    }
    static let entity = "users"
    
    @Field var id: Int?
    @Field var name: String
    @Field var pet: Pet

    init() { }

    init(id: Int? = nil, name: String, pet: Pet) {
        self.id = id
        self.name = name
        self.pet = pet
    }
}

struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return User.schema(on: database)
            .field(\.$id, .int, .identifier(auto: true))
            .field(\.$name, .string, .required)
            .field(\.$pet, .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return User.schema(on: database).delete()
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
