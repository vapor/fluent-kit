import FluentKit

final class Planet: Model {
    var id = Field<Int>()
    var name = Field<String>()
    var galaxy = Parent<Galaxy>()

    init(id: Int? = nil, name: String, galaxyID: Galaxy.ID) {
        if let id = id {
            self.id.value = id
        }
        self.name.value = name
        self.galaxy.id.value = galaxyID
    }

    init(storage: ModelStorage) {
        fatalError()
    }

    static func name(for keyPath: PartialKeyPath<Planet>) -> String? {
        switch keyPath {
        case \Planet.id: return "id"
        case \Planet.name: return "name"
        case \Planet.galaxy: return "galaxyID"
        default: return nil
        }
    }

    static func fields() -> [(PartialKeyPath<Planet>, Any.Type)] {
        return [
            (\Planet.id as PartialKeyPath<Planet>, Int.self),
            (\Planet.name as PartialKeyPath<Planet>, String.self),
            (\Planet.galaxy as PartialKeyPath<Planet>, Galaxy.self),
        ]
    }

    static func dataType(for keyPath: PartialKeyPath<Planet>) -> DatabaseSchema.DataType? {
        return nil
    }

    static func constraints(for keyPath: PartialKeyPath<Planet>) -> [DatabaseSchema.FieldConstraint]? {
        return nil
    }
}
