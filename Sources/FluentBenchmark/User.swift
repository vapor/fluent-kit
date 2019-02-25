import FluentKit



final class User: Model {
    var storage: ModelStorage
    
    var properties: [Property] {
        return [id, name, pet.property]
    }
    
    var entity: String {
        return "users"
    }
    
    var id: Field<Int> {
        return self.field("id", .int, .identifier)
    }
    
    var name: Field<String> {
        return self.field("name", .string, .required)
    }
    
    var pet: Pet {
        return self.nested("pet", .json, .required)
    }
    
    init(storage: ModelStorage) {
        self.storage = storage
    }
}

enum Animal: String, Codable {
    case cat, dog
}

final class Pet: NestedModel {
    var storage: ModelStorage
    
    var properties: [Property] {
        return [name, type]
    }
    
    var name: Field<String> {
        return self.field("name")
    }
    
    var type: Field<Animal> {
        return self.field("type")
    }
    
    init(storage: ModelStorage) {
        self.storage = storage
    }
}

final class UserSeed: Migration {
    init() { }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let tanner = User()
        tanner.name.set(to: "Tanner")
        tanner.pet.name.set(to: "Ziz")
        tanner.pet.type.set(to: .cat)

        let logan =  User()
        logan.name.set(to: "Logan")
        logan.pet.name.set(to: "Runa")
        logan.pet.type.set(to: .dog)
        
        return logan.save(on: database)
            .and(tanner.save(on: database))
            .map { _ in }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
