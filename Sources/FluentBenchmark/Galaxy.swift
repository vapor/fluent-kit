import FluentKit

final class Galaxy: Model {
    var id = Field<Int>()
    var name = Field<String>()
    var planets = Children<Planet>(\.galaxy)

    init(id: Int? = nil, name: String) {
        if let id = id {
            self.id.value = id
        }
        self.name.value = name
    }

    init(storage: ModelStorage) {
        fatalError()
    }

    static func name(for keyPath: PartialKeyPath<Galaxy>) -> String? {
        switch keyPath {
        case \Galaxy.id: return "id"
        case \Galaxy.name: return "name"
        case \Galaxy.planets: return "planets"
        default: return nil
        }
    }

    static func fields() -> [(PartialKeyPath<Galaxy>, Any.Type)] {
        return [
            (\Galaxy.id as PartialKeyPath<Galaxy>, Int.self),
            (\Galaxy.name as PartialKeyPath<Galaxy>, String.self),
            (\Galaxy.planets as PartialKeyPath<Galaxy>, [Planet].self),
        ]
    }

    static func dataType(for keyPath: PartialKeyPath<Galaxy>) -> DatabaseSchema.DataType? {
        return nil
    }

    static func constraints(for keyPath: PartialKeyPath<Galaxy>) -> [DatabaseSchema.FieldConstraint]? {
        return nil
    }
}
