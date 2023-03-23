import FluentKit
import Foundation
import NIOCore
import XCTest

public final class Planet: Model {
    public static let schema = "planets"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Parent(key: "star_id")
    public var star: Star

    @OptionalParent(key: "possible_star_id")
    public var possibleStar: Star?

    @Children(for: \.$planet)
    public var moons: [Moon]
    
    @OptionalChild(for: \.$planet)
    public var governor: Governor?

    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    public init() { }

    public init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }

    public init(id: IDValue? = nil, name: String, starId: UUID) {
        self.id = id
        self.name = name
        self.$star.id = starId
    }
}

public struct PlanetMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("planets")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("star_id", .uuid, .required, .references("stars", "id"))
            .field("possible_star_id", .uuid, .references("stars", "id"))
            .field("deleted_at", .datetime)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("planets").delete()
    }
}

public struct PlanetSeed: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        Star.query(on: database).all().flatMap { stars in
            .andAllSucceed(stars.map { star in
                let planets: [Planet]
                switch star.name {
                case "Sun":
                    planets = [
                        .init(name: "Mercury"),
                        .init(name: "Venus"),
                        .init(name: "Earth"),
                        .init(name: "Mars"),
                        .init(name: "Jupiter"),
                        .init(name: "Saturn"),
                        .init(name: "Uranus"),
                        .init(name: "Nepture"),
                    ]
                case "Alpha Centauri":
                    planets = [
                        .init(name: "Proxima Centauri b")
                    ]
                default:
                    planets = []
                }
                return star.$planets.create(planets, on: database)
            }, on: database.eventLoop)
        }
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Planet.query(on: database).delete(force: true)
    }
}
