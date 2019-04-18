import FluentKit

final class Galaxy: Model {
    var id = Field<Int>("id")
    var name = Field<String>("name")
    var planets = Children<Planet>(\.galaxy)
    let storage: ModelStorage

    convenience init(id: Int? = nil, name: String) {
        self.init()
        if let id = id {
            self.id.value = id
        }
        self.name.value = name
    }

    init(storage: ModelStorage) {
        self.storage = storage
    }
}
