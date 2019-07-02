import FluentKit

final class Galaxy: Model {
    @Field("id") var id: Int?
    @Field("name") var name: String
    @Relation("galaxy_id") var planets: Children<Planet>

    init() { }

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
