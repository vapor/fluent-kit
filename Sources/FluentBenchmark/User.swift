import FluentKit

final class User: Model {
    struct Pet: Codable, NestedProperty {
        enum Animal: String, Codable {
            case cat, dog
        }
        var name: String
        var type: Animal
    }
    
    static let entity = "users"
    
    var id = Field<Int>("id")
    var name = Field<String>("name")
    var pet = Field<Pet>("pet")
    let storage: ModelStorage

    convenience init(id: Int? = nil, name: String, pet: Pet) {
        self.init()
        if let id = id {
            self.id.value = id
        }
        self.name.value = name
        self.pet.value = pet
    }

    init(storage: ModelStorage) {
        self.storage = storage
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
