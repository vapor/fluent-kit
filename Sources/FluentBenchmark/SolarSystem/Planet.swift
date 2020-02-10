import FluentKit

public final class Planet: Model {
    public static let schema = "planets"

    @ID(key: "id")
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Parent(key: "star_id")
    public var star: Star

    @Children(for: \.$planet)
    public var moons: [Moon]

    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]

    public init() { }

    public init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
        self.$star.id = starID
    }
}

public struct PlanetMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planets")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("star_id", .int, .required, .references("stars", "id"))
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planets").delete()
    }
}

final class PlanetSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        Galaxy.query(on: database).all().flatMap {
            let stars: [Star]
            switch $0.name {
            case "Milky Way":
            case "Andromeda":
                return $0.$stars.create([
                    Star(
                ], on: database)
            default:
                stars = []
            }
            return $0.$stars.create(stars, on: database))
        }
        let milkyWay = self.add([
            "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"
        ], to: "Milky Way", on: database)
        let andromeda = self.add(["PA-99-N2"], to: "Andromeda", on: database)
        return .andAllSucceed([

        ], on: database.eventLoop)
    }

    private func add(_ planet: String, to star: String, on database: Database) -> EventLoopFuture<Void> {
        return Star.query(on: database)
            .filter(\.$name == star)
            .first()
            .flatMap {
                guard let star = $0 else {
                    return database.eventLoop.makeSucceededFuture(())
                }
                return star.$planets.save(Planet(name: planet), on: database)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
