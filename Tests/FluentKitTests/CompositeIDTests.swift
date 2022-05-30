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
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "composite+planet+tag"("planet_id" UUID NOT NULL REFERENCES "planets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION, "tag_id" UUID NOT NULL REFERENCES "tags" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION, "notation" TEXT NOT NULL, "createdAt" TIMESTAMPTZ, "updatedAt" TIMESTAMPTZ, PRIMARY KEY ("planet_id", "tag_id"))"#)
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
    
    @Field(key: "notation")
    public var notation: String
    
    @Timestamp(key: "createdAt", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    public var updatedAt: Date?

    @Timestamp(key: "deletedAt", on: .delete)
    public var deletedAt: Date?

    public init() {}

    public init(planetID: Planet.IDValue, tagID: Tag.IDValue) {
        self.id = .init(planetID: planetID, tagID: tagID)
    }
}

public struct CompositePlanetTagMigration: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositePlanetTag.schema)
            .field("planet_id", .uuid, .required, .references(Planet.schema, "id"))
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
