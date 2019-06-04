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
    static let shared = User()
    
    let id = Field<Int?>("id")
    let name = Field<String>("name")
    let pet = Field<Pet>("pet", dataType: .json)
}


final class UserSeed: Migration {
    init() { }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let tanner = User.new()
        tanner.name = "Tanner"
        tanner.pet = .init(name: "Ziz", type: .cat)

        let logan = User.new()
        logan.name = "Logan"
        logan.pet = .init(name: "Runa", type: .dog)
        
        return logan.save(on: database)
            .and(tanner.save(on: database))
            .map { _ in }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
