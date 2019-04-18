import FluentKit

final class Planet: Model {
    var id = Field<Int>("id")
    var name = Field<String>("name")
    var galaxy = Parent<Galaxy>("galaxyID")
    let storage: ModelStorage

    convenience init(id: Int? = nil, name: String, galaxyID: Galaxy.ID) {
        self.init()
        if let id = id {
            self.id.value = id
        }
        self.name.value = name
        self.galaxy.id.value = galaxyID
    }

    init(storage: ModelStorage) {
        self.storage = storage
    }
}
