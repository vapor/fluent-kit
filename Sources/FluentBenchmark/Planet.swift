import FluentKit

final class Planet: Model {
    static let shared = Planet()
    let id = Field<Int>("id")
    let name = Field<String>("name")
    let galaxy = Parent<Galaxy>("galaxyID")
}
