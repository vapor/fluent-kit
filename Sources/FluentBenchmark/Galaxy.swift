import FluentKit

struct Galaxy: Model {
    static let shared = Galaxy()
    let id = Field<Int>("id")
    let name = Field<String>("name")
    let planets = Children<Planet>("galaxyID")
}
