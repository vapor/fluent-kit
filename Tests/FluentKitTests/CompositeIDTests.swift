import FluentKit
import FluentBenchmark
import XCTest
import Foundation
import FluentSQL
import XCTFluent

extension Collection {
    func xctAt(_ idx: Self.Index, file: StaticString = #fileID, line: UInt = #line) throws -> Self.Element {
        let idx = try XCTUnwrap(self.indices.first { $0 == idx }, file: (file), line: line)
        return self[idx]
    }
}

final class CompositeIDTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }

    func testCompositeModelCRUD() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let model = CompositePlanetTag(
            planetID: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
            tagID: .init(uuidString: "11111111-1111-1111-1111-111111111111")!
        )
        
        model.notation = "composition"
        _ = try model.create(on: db).wait()
        XCTAssertTrue(model.$id.exists)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        model.notation = "revision"
        XCTAssertTrue(model.hasChanges)
        try model.update(on: db).wait()
        XCTAssertNotEqual(model.createdAt, model.updatedAt)
        XCTAssertFalse(model.hasChanges)
        
        model.$id.$planet.id = .init(uuidString: "22222222-2222-2222-2222-222222222222")!
        XCTAssertTrue(model.hasChanges)
        try model.update(on: db).wait()
        XCTAssertNotEqual(model.createdAt, model.updatedAt)
        XCTAssertFalse(model.hasChanges)
        
        try model.delete(force: false, on: db).wait()
        try model.restore(on: db).wait()
        try model.delete(force: true, on: db).wait()

        XCTAssertEqual(db.sqlSerializers.count, 6)
        XCTAssertEqual(try db.sqlSerializers.xctAt(0).sql, #"INSERT INTO "composite+planet+tag" ("createdAt", "notation", "tag_id", "planet_id", "updatedAt") VALUES ($1, $2, $3, $4, $5)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(1).sql, #"UPDATE "composite+planet+tag" SET "updatedAt" = $1, "notation" = $2 WHERE ("composite+planet+tag"."planet_id" = $3 AND "composite+planet+tag"."tag_id" = $4) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $5)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(2).sql, #"UPDATE "composite+planet+tag" SET "updatedAt" = $1, "planet_id" = $2 WHERE ("composite+planet+tag"."planet_id" = $3 AND "composite+planet+tag"."tag_id" = $4) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $5)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(3).sql, #"UPDATE "composite+planet+tag" SET "updatedAt" = $1, "deletedAt" = $2 WHERE ("composite+planet+tag"."planet_id" = $3 AND "composite+planet+tag"."tag_id" = $4) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $5)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(4).sql, #"UPDATE "composite+planet+tag" SET "updatedAt" = $1, "deletedAt" = NULL WHERE ("composite+planet+tag"."planet_id" = $2 AND "composite+planet+tag"."tag_id" = $3)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(5).sql, #"DELETE FROM "composite+planet+tag" WHERE ("composite+planet+tag"."planet_id" = $1 AND "composite+planet+tag"."tag_id" = $2)"#)
    }
    
    func testCompositeModelQuery() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let model = CompositePlanetTag(
            planetID: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
            tagID: .init(uuidString: "11111111-1111-1111-1111-111111111111")!
        )
        
        _ = try CompositePlanetTag.find(.init(planetID: model.id!.$planet.id, tagID: model.id!.$tag.id), on: db).wait()

        _ = try CompositePlanetTag.query(on: db).filter(\.$id.$planet.$id == model.id!.$planet.id).filter(\.$id.$tag.$id == model.id!.$tag.id).all().wait()

        _ = try CompositePlanetTag.query(on: db).filter(\.$id.$planet.$id == model.id!.$planet.id).all().wait()

        _ = try CompositePlanetTag.query(on: db).filter(\.$id.$tag.$id == model.id!.$tag.id).withDeleted().all().wait()

        XCTAssertEqual(db.sqlSerializers.count, 4)
        XCTAssertEqual(try db.sqlSerializers.xctAt(0).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE ("composite+planet+tag"."planet_id" = $1 AND "composite+planet+tag"."tag_id" = $2) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $3) LIMIT 1"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(1).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE "composite+planet+tag"."planet_id" = $1 AND "composite+planet+tag"."tag_id" = $2 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $3)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(2).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE "composite+planet+tag"."planet_id" = $1 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $2)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(3).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE "composite+planet+tag"."tag_id" = $1"#)
    }
    
    func testCompositeIDMigration() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try CompositePlanetTagMigration().prepare(on: db).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "composite+planet+tag"("planet_id" UUID NOT NULL REFERENCES "planets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION, "tag_id" UUID NOT NULL REFERENCES "tags" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION, "notation" TEXT NOT NULL, "createdAt" TIMESTAMPTZ, "updatedAt" TIMESTAMPTZ, "deletedAt" TIMESTAMPTZ, PRIMARY KEY ("planet_id", "tag_id"))"#)
    }
    
    func testCompositeIDRelations() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let model = CompositePlanetTag(
            planetID: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
            tagID: .init(uuidString: "11111111-1111-1111-1111-111111111111")!
        )
        let planet = PlanetUsingCompositePivot(id: model.$id.$planet.id, name: "Planet", starId: .init(uuidString: "22222222-2222-2222-2222-222222222222")!)
        planet.$planetTags.fromId = planet.id!
        planet.$tags.fromId = planet.id!
        let tag = Tag(id: .init(uuidString: "33333333-3333-3333-3333-333333333333")!, name: "Tag")
        
        _ = try model.$id.$planet.get(on: db).wait()
        _ = try planet.$planetTags.get(on: db).wait()
        _ = try planet.$tags.get(on: db).wait()
                
        try planet.$planetTags.create(model, on: db).wait()
        try planet.$tags.attach(tag, method: .always, on: db).wait()
        try planet.$tags.attach(tag, method: .ifNotExists, on: db).wait()
        _ = try planet.$tags.isAttached(to: tag, on: db).wait()
        try planet.$tags.detach(tag, on: db).wait()
        try planet.$tags.detachAll(on: db).wait()
        
        XCTAssertEqual(db.sqlSerializers.count, 9)
        XCTAssertEqual(try db.sqlSerializers.xctAt(0).sql, #"SELECT "planets"."id" AS "planets_id", "planets"."name" AS "planets_name", "planets"."star_id" AS "planets_star_id" FROM "planets" WHERE "planets"."id" = $1 LIMIT 1"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(1).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE "composite+planet+tag"."planet_id" = $1 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $2)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(2).sql, #"SELECT "tags"."id" AS "tags_id", "tags"."name" AS "tags_name", "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "tags" INNER JOIN "composite+planet+tag" ON "tags"."id" = "composite+planet+tag"."tag_id" WHERE "composite+planet+tag"."planet_id" = $1 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $2)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(3).sql, #"INSERT INTO "composite+planet+tag" ("createdAt", "tag_id", "updatedAt", "planet_id") VALUES ($1, $2, $3, $4)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(4).sql, #"INSERT INTO "composite+planet+tag" ("createdAt", "tag_id", "updatedAt", "planet_id") VALUES ($1, $2, $3, $4)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(5).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE "composite+planet+tag"."planet_id" = $1 AND "composite+planet+tag"."tag_id" = $2 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $3) LIMIT 1"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(6).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE "composite+planet+tag"."planet_id" = $1 AND "composite+planet+tag"."tag_id" = $2 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $3) LIMIT 1"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(7).sql, #"UPDATE "composite+planet+tag" SET "updatedAt" = $1, "deletedAt" = $2 WHERE "composite+planet+tag"."planet_id" = $3 AND "composite+planet+tag"."tag_id" = $4 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $5)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(8).sql, #"UPDATE "composite+planet+tag" SET "updatedAt" = $1, "deletedAt" = $2 WHERE "composite+planet+tag"."planet_id" = $3 AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $4)"#)
    }
    
    func testCompositeIDFilterByID() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let planetId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            tagId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        
        _ = try CompositePlanetTag.query(on: db).filter(\.$id == CompositePlanetTag.IDValue.init(planetID: planetId, tagID: tagId)).all().wait()
        _ = try CompositePlanetTag.query(on: db).filter(\.$id != CompositePlanetTag.IDValue.init(planetID: planetId, tagID: tagId)).all().wait()
        
        XCTAssertEqual(db.sqlSerializers.count, 2)
        XCTAssertEqual(try db.sqlSerializers.xctAt(0).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE ("composite+planet+tag"."planet_id" = $1 AND "composite+planet+tag"."tag_id" = $2) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $3)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(1).sql, #"SELECT "composite+planet+tag"."planet_id" AS "composite+planet+tag_planet_id", "composite+planet+tag"."tag_id" AS "composite+planet+tag_tag_id", "composite+planet+tag"."notation" AS "composite+planet+tag_notation", "composite+planet+tag"."createdAt" AS "composite+planet+tag_createdAt", "composite+planet+tag"."updatedAt" AS "composite+planet+tag_updatedAt", "composite+planet+tag"."deletedAt" AS "composite+planet+tag_deletedAt" FROM "composite+planet+tag" WHERE ("composite+planet+tag"."planet_id" <> $1 OR "composite+planet+tag"."tag_id" <> $2) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $3)"#)
    }
}

public final class PlanetUsingCompositePivot: Model {
    public static let schema = Planet.schema
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: "name")
    public var name: String

    @Parent(key: "star_id")
    public var star: Star

    @Children(for: \.$id.$planet)
    public var planetTags: [CompositePlanetTag]
    
    @Siblings(through: CompositePlanetTag.self, from: \.$id.$planet, to: \.$id.$tag)
    public var tags: [Tag]
    
    public init() {}

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

public final class CompositePlanetTag: Model {
    public static let schema = "composite+planet+tag"
    
    public final class IDValue: Fields, Hashable {
        @Parent(key: "planet_id")
        public var planet: PlanetUsingCompositePivot
        
        @Parent(key: "tag_id")
        public var tag: Tag
        
        public init() {}
        
        public init(planetID: PlanetUsingCompositePivot.IDValue, tagID: Tag.IDValue) {
            self.$planet.id = planetID
            self.$tag.id = tagID
        }
        
        public convenience init(planet: PlanetUsingCompositePivot, tag: Tag) throws {
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
    
    @Field(key: "notation")
    public var notation: String
    
    @Timestamp(key: "createdAt", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    public var updatedAt: Date?

    @Timestamp(key: "deletedAt", on: .delete)
    public var deletedAt: Date?

    public init() {}

    public init(planetID: PlanetUsingCompositePivot.IDValue, tagID: Tag.IDValue) {
        self.id = .init(planetID: planetID, tagID: tagID)
    }
}

public struct CompositePlanetTagMigration: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositePlanetTag.schema)
            .field("planet_id", .uuid, .required, .references(PlanetUsingCompositePivot.schema, "id"))
            .field("tag_id", .uuid, .required, .references(Tag.schema, "id"))
            .field("notation", .string, .required)
            .field("createdAt", .datetime)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .compositeIdentifier(over: "planet_id", "tag_id")
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositePlanetTag.schema).delete()
    }
}
