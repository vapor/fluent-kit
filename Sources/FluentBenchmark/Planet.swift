import FluentKit

final class Planet: Model {
    @Field var id: Int?
    @Field var name: String
    @Relation var galaxy: Parent<Galaxy>

    init() { }

    init(id: Int? = nil, name: String, galaxyID: Galaxy.ID) {
        self.id = id
        self.name = name
        self.galaxy.id = galaxyID
    }
}
