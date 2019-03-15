import FluentKit

final class Galaxy: Model {
    struct Properties: ModelProperties {
        let id = Field<Int>("id")
        let name = Field<String>("name")
        let planets = Children<Planet>(id: .init("galaxyID"))
    }
    static let properties = Properties()
    
    var storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}
