import FluentKit

final class Planet: Model {
    struct Properties: ModelProperties {
        let id = Field<Int>("id")
        let name = Field<String>("name")
        let galaxy = Parent<Galaxy>(id: Field("galaxyID"))
    }
    static let properties = Properties()
    var storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}
