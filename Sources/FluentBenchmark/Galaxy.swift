import FluentKit

final class Galaxy: Model {
    @Field var id: Int?
    @Field var name: String
    @Children(\.$galaxy) var planets: [Planet]

    init() {
        self.initialize()
    }

    convenience init(id: Int? = nil, name: String) {
        self.init()
        self.id = id
        self.name = name
    }
}
