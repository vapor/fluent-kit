import FluentKit

final class Planet: Model {
    static let `default` = Planet()
    let id = Field<Int>("id")
    let name = Field<String>("name")
    let galaxy = Parent<Galaxy>(id: Field("galaxyID"))
}
