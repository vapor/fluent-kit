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
    
    var id = Field<Int>()
    var name = Field<String>()
    var pet = Field<Pet>()

    init(id: Int? = nil, name: String, pet: Pet) {
        if let id = id {
            self.id.value = id
        }
        self.name.value = name
        self.pet.value = pet
    }

    init(storage: ModelStorage) {
        fatalError()
    }

    static func name(for keyPath: PartialKeyPath<User>) -> String? {
        switch keyPath {
        case \User.id: return "id"
        case \User.name: return "name"
        case \User.pet: return "pet"
        default: return nil
        }
    }

    static func fields() -> [(PartialKeyPath<User>, Any.Type)] {
        return [
            (\User.id as PartialKeyPath<User>, Int.self),
            (\User.name as PartialKeyPath<User>, String.self),
            (\User.pet as PartialKeyPath<User>, Pet.self),
        ]
    }

    static func dataType(for keyPath: PartialKeyPath<User>) -> DatabaseSchema.DataType? {
        switch keyPath {
        case \User.pet: return .json
        default: return nil
        }
    }

    static func constraints(for keyPath: PartialKeyPath<User>) -> [DatabaseSchema.FieldConstraint]? {
        return nil
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
