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
    
    @Field("id") var id: Int?
    @Field("name") var name: String
    @Field("pet") var pet: Pet

    init() {
        self.initialize()
    }

    convenience init(id: Int? = nil, name: String, pet: Pet) {
        self.init()
        self.id = id
        self.name = name
        self.pet = pet
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
