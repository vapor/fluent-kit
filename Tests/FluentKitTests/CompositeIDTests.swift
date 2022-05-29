import FluentKit
import FluentBenchmark
import XCTest
import Foundation
import FluentSQL
import XCTFluent

final class CompositeIDTests: XCTestCase {
    func testBasicCompositeModel() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let model = CompositePlanetTag(
            planetID: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
            tagID: .init(uuidString: "11111111-1111-1111-1111-111111111111")!
        )
        
        _ = try model.create(on: db).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"INSERT INTO "composite+planet+tag" ("createdAt", "planet_id", "tag_id") VALUES ($1, $2, $3)"#)
        db.reset()
        
        _ = try CompositePlanetTag.find(.init(planetID: model.id!.$planet.id, tagID: model.id!.$tag.id), on: db).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt" FROM "composite+planet+tag" WHERE ("composite+planet+tag"."planet_id" = $1 AND "composite+planet+tag"."tag_id" = $2) LIMIT 1""#)
    }
}

public final class CompositePlanetTag: Model {
    public static let schema = "composite+planet+tag"
    
    public final class IDValue: Fields, Hashable {
        @Parent(key: "planet_id")
        public var planet: Planet
        
        @Parent(key: "tag_id")
        public var tag: Tag
        
        public init() {}
        
        public init(planetID: Planet.IDValue, tagID: Tag.IDValue) {
            self.$planet.id = planetID
            self.$tag.id = tagID
        }
        
        public convenience init(planet: Planet, tag: Tag) throws {
            try self.init(planetID: planet.requireID(), tagID: tag.requireID())
        }
        
        public static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.$planet.id == rhs.$planet.id && lhs.$tag.id == rhs.$tag.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.$planet.id)
            hasher.combine(self.$tag.id)
        }
    }
    
    @CompositeID
    public var id: IDValue?

    @Timestamp(key: "createdAt", on: .create)
    public var createdAt: Date?

    public init() {}

    public init(planetID: Planet.IDValue, tagID: Tag.IDValue) {
        self.id = .init(planetID: planetID, tagID: tagID)
    }
}

public struct PlanetTagMigration: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositePlanetTag.schema)
            .field("planet_id", .uuid, .required, .references(Planet.schema, "id"))
            .field("tag_id", .uuid, .required, .references(Tag.schema, "id"))
            .compositeIdentifier(over: "planet_id", "tag_id")
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositePlanetTag.schema).delete()
    }
}
