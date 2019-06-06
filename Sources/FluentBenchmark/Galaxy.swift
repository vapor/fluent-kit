import FluentKit

final class Galaxy: Model {
    @Field var id: Int?
    @Field var name: String
    @Relation var planets: Children<Planet>

    init() { }

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
