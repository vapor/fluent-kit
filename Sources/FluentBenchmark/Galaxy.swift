import FluentKit

final class Galaxy: Model {
    @Field var id: Int?
    @Field var name: String
    @Children(\.$galaxy) var planets: [Planet]

    init() {
        self.new()
    }

    init(id: Int? = nil, name: String) {
        self.new()
        self.id = id
        self.name = name
    }
}
