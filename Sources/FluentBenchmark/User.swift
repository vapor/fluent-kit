import FluentKit

final class User: Model {
    struct Pet: Codable, NestedProperty {
        enum Animal: String, Codable {
            case cat, dog
        }
        var name: String
        var type: Animal
    }
    
    struct Properties: ModelProperties {
        let id = Field<Int>("id")
        let name = Field<String>("name")
        let pet = Field<Pet>("pet", dataType: .json)
    }
    
    static let entity: String = "users"
    static let properties = Properties()
    
    var storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}


final class UserSeed: Migration {
    init() { }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let tanner = User()
        tanner.set(\.name, to: "Tanner")
        tanner.set(\.pet, to: .init(name: "Ziz", type: .cat))

        let logan = User()
        logan.set(\.name, to: "Logan")
        logan.set(\.pet, to: .init(name: "Runa", type: .dog))
        
        return logan.save(on: database)
            .and(tanner.save(on: database))
            .map { _ in }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
