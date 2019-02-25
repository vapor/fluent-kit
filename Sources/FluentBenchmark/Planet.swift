import FluentKit

final class Planet: Model, Codable {
    var storage: ModelStorage
    
    var properties: [Property] {
        return [id, name, galaxy]
    }
    
    var entity: String {
        return "planets"
    }
    
    var id: Field<Int> {
        return self.field("id", .int, .identifier)
    }
    
    var name: Field<String> {
        return self.field("name")
    }
    
    var galaxy: Parent<Galaxy> {
        return self.parent("galaxyID")
    }
    
    init(storage: ModelStorage) {
        self.storage = storage
    }
}
