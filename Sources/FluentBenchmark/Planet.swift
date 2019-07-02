import FluentKit

final class Planet: Model {
    @Field("id") var id: Int?
    @Field("name") var name: String
    @Relation("galaxy_id") var galaxy: Parent<Galaxy>

    init() { }

    init(id: Int? = nil, name: String, galaxyID: Galaxy.ID) {
        self.id = id
        self.name = name
        self.galaxy.id = galaxyID
    }
}
