import FluentKit

struct Galaxy: Model {
    static let `default` = Galaxy()
    let id = Field<Int>("id")
    let name = Field<String>("name")
    let planets = Children<Planet>(id: .init("galaxyID"))
}
