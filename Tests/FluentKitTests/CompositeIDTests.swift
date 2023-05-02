import FluentKit
import FluentBenchmark
import XCTest
import Foundation
import FluentSQL
import XCTFluent
import NIOCore

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
        XCTAssertEqual(try db.sqlSerializers.xctAt(0).sql, #"INSERT INTO "composite+planet+tag" ("planet_id", "tag_id", "notation", "createdAt", "updatedAt") VALUES ($1, $2, $3, $4, $5)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(1).sql, #"UPDATE "composite+planet+tag" SET "notation" = $1, "updatedAt" = $2 WHERE ("composite+planet+tag"."planet_id" = $3 AND "composite+planet+tag"."tag_id" = $4) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $5)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(2).sql, #"UPDATE "composite+planet+tag" SET "planet_id" = $1, "updatedAt" = $2 WHERE ("composite+planet+tag"."planet_id" = $3 AND "composite+planet+tag"."tag_id" = $4) AND ("composite+planet+tag"."deletedAt" IS NULL OR "composite+planet+tag"."deletedAt" > $5)"#)
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
        XCTAssertEqual(try db.sqlSerializers.xctAt(3).sql, #"INSERT INTO "composite+planet+tag" ("planet_id", "tag_id", "createdAt", "updatedAt") VALUES ($1, $2, $3, $4)"#)
        XCTAssertEqual(try db.sqlSerializers.xctAt(4).sql, #"INSERT INTO "composite+planet+tag" ("planet_id", "tag_id", "createdAt", "updatedAt") VALUES ($1, $2, $3, $4)"#)
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
    
    func testCompositeParentAndChildQuerying() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let systemId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        
        _ = try CompositeMoon(name: "", planetSolarSystemId: systemId, planetNormalizedOrdinal: 1).$orbiting.query(on: db).all().wait()
        _ = try CompositeMoon(name: "", planetSolarSystemId: systemId, planetNormalizedOrdinal: 1, progenitorId: .init(solarSystemId: systemId, normalizedOrdinal: 2)).$progenitor.query(on: db).all().wait()
        _ = try CompositeMoon(name: "", planetSolarSystemId: systemId, planetNormalizedOrdinal: 1, progenitorId: nil).$progenitor.query(on: db).all().wait()
        _ = try CompositeMoon(name: "", planetSolarSystemId: systemId, planetNormalizedOrdinal: 1, progenitorId: nil, planetoidId: .init(solarSystemId: systemId, normalizedOrdinal: 3)).$planetoid.query(on: db).all().wait()
        _ = try CompositeMoon(name: "", planetSolarSystemId: systemId, planetNormalizedOrdinal: 1, progenitorId: nil, planetoidId: nil).$planetoid.query(on: db).all().wait()
        _ = try CompositePlanet(name: "", solarSystemId: systemId, normalizedOrdinal: 1).$moons.query(on: db).all().wait()
        _ = try CompositePlanet(name: "", solarSystemId: systemId, normalizedOrdinal: 2).$moonsMade.query(on: db).all().wait()
        _ = try CompositePlanet(name: "", solarSystemId: systemId, normalizedOrdinal: 3).$fragment.query(on: db).all().wait()
                
        let allPlanetFields = #""composite+planet"."system_id" AS "composite+planet_system_id", "composite+planet"."nrm_ord" AS "composite+planet_nrm_ord", "composite+planet"."name" AS "composite+planet_name" FROM "composite+planet""#
        let allMoonFields = #""composite+moon"."id" AS "composite+moon_id", "composite+moon"."name" AS "composite+moon_name", "composite+moon"."planet_system_id" AS "composite+moon_planet_system_id", "composite+moon"."planet_nrm_ord" AS "composite+moon_planet_nrm_ord", "composite+moon"."progenitorSystem_id" AS "composite+moon_progenitorSystem_id", "composite+moon"."progenitorNrm_ord" AS "composite+moon_progenitorNrm_ord", "composite+moon"."planetoid_system_id" AS "composite+moon_planetoid_system_id", "composite+moon"."planetoid_nrm_ord" AS "composite+moon_planetoid_nrm_ord" FROM "composite+moon""#
        
        let expectedQueries: [(String, [Encodable])] = [
            (#"SELECT \#(allPlanetFields) WHERE ("composite+planet"."system_id" = $1 AND "composite+planet"."nrm_ord" = $2)"#,               [systemId, 1]),
            (#"SELECT \#(allPlanetFields) WHERE ("composite+planet"."system_id" = $1 AND "composite+planet"."nrm_ord" = $2)"#,               [systemId, 2]),
            (#"SELECT \#(allPlanetFields) WHERE ("composite+planet"."system_id" IS NULL AND "composite+planet"."nrm_ord" IS NULL)"#,         []),
            (#"SELECT \#(allPlanetFields) WHERE ("composite+planet"."system_id" = $1 AND "composite+planet"."nrm_ord" = $2)"#,               [systemId, 3]),
            (#"SELECT \#(allPlanetFields) WHERE ("composite+planet"."system_id" IS NULL AND "composite+planet"."nrm_ord" IS NULL)"#,         []),
            (#"SELECT \#(allMoonFields) WHERE ("composite+moon"."planet_system_id" = $1 AND "composite+moon"."planet_nrm_ord" = $2)"#,       [systemId, 1]),
            (#"SELECT \#(allMoonFields) WHERE ("composite+moon"."progenitorSystem_id" = $1 AND "composite+moon"."progenitorNrm_ord" = $2)"#, [systemId, 2]),
            (#"SELECT \#(allMoonFields) WHERE ("composite+moon"."planetoid_system_id" = $1 AND "composite+moon"."planetoid_nrm_ord" = $2)"#, [systemId, 3]),
        ]
        XCTAssertEqual(db.sqlSerializers.count, expectedQueries.count)
        for ((query, binds), serializer) in zip(expectedQueries, db.sqlSerializers) {
            XCTAssertEqual(serializer.sql, query)
            XCTAssertEqual(serializer.binds.count, binds.count)
            for (lBind, rBind) in zip(binds, serializer.binds) {
                XCTAssertEqual("\(lBind)", "\(rBind)")
            }
        }
    }
    
    func testCompositeParentChildMutating() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let sysId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, sys2Id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        
        let planet1 = CompositePlanet(name: "A", solarSystemId: sysId, normalizedOrdinal: 1)
        let moon1 = CompositeMoon(name: "B", planetSolarSystemId: sysId, planetNormalizedOrdinal: 1)
        let moon2 = CompositeMoon(name: "C", planetSolarSystemId: sysId, planetNormalizedOrdinal: 1, progenitorId: .init(solarSystemId: sysId, normalizedOrdinal: 2))
        let moon3 = CompositeMoon(name: "D", planetSolarSystemId: sysId, planetNormalizedOrdinal: 1)
        let moon4 = CompositeMoon(name: "E", planetSolarSystemId: sysId, planetNormalizedOrdinal: 1, planetoidId: .init(solarSystemId: sysId, normalizedOrdinal: 3))
        
        try planet1.create(on: db).wait()
        try [moon1, moon2, moon3, moon4].forEach { try $0.create(on: db).wait() }
        
        planet1.name = "AA"
        try planet1.update(on: db).wait()
        
        moon1.$orbiting.id.$solarSystem.id = sys2Id
        moon1.$orbiting.id.normalizedOrdinal = 2
        moon2.$progenitor.id = nil
        moon3.$planetoid.id = .init(solarSystemId: sys2Id, normalizedOrdinal: 3)
        moon4.$planetoid.id = nil
        try [moon1, moon2, moon3, moon4].forEach { try $0.update(on: db).wait() }
        
        let moonCols = #""id", "name", "planet_system_id", "planet_nrm_ord""#, fourVals = "$1, $2, $3, $4", sixVals = "\(fourVals), $5, $6"
        let expectedQueries: [(String, [Encodable])] = [
            (#"INSERT INTO "composite+planet" ("system_id", "nrm_ord", "name") VALUES ($1, $2, $3)"#,                                         [sysId, 1, "A"]),
            (#"INSERT INTO "composite+moon" (\#(moonCols)) VALUES (\#(fourVals))"#,                                                           [moon1.id!, "B", sysId, 1]),
            (#"INSERT INTO "composite+moon" (\#(moonCols), "progenitorSystem_id", "progenitorNrm_ord") VALUES (\#(sixVals))"#,                [moon2.id!, "C", sysId, 1, sysId, 2]),
            (#"INSERT INTO "composite+moon" (\#(moonCols)) VALUES (\#(fourVals))"#,                                                           [moon3.id!, "D", sysId, 1]),
            (#"INSERT INTO "composite+moon" (\#(moonCols), "planetoid_system_id", "planetoid_nrm_ord") VALUES (\#(sixVals))"#,                [moon4.id!, "E", sysId, 1, sysId, 3]),
            (#"UPDATE "composite+planet" SET "name" = $1 WHERE ("composite+planet"."system_id" = $2 AND "composite+planet"."nrm_ord" = $3)"#, ["AA", sysId, 1]),
            (#"UPDATE "composite+moon" SET "planet_system_id" = $1, "planet_nrm_ord" = $2 WHERE "composite+moon"."id" = $3"#,                 [sys2Id, 2, moon1.id!]),
            (#"UPDATE "composite+moon" SET "progenitorSystem_id" = NULL, "progenitorNrm_ord" = NULL WHERE "composite+moon"."id" = $1"#,       [moon2.id!]),
            (#"UPDATE "composite+moon" SET "planetoid_system_id" = $1, "planetoid_nrm_ord" = $2 WHERE "composite+moon"."id" = $3"#,           [sys2Id, 3, moon3.id!]),
            (#"UPDATE "composite+moon" SET "planetoid_system_id" = NULL, "planetoid_nrm_ord" = NULL WHERE "composite+moon"."id" = $1"#,       [moon4.id!]),
        ]

        XCTAssertEqual(db.sqlSerializers.count, expectedQueries.count)
        for ((query, binds), serializer) in zip(expectedQueries, db.sqlSerializers) {
            XCTAssertEqual(serializer.sql, query)
            XCTAssertEqual(serializer.binds.count, binds.count)
            for (lBind, rBind) in zip(binds, serializer.binds) {
                XCTAssertEqual("\(lBind)", "\(rBind)")
            }
        }
    }
    
    func testCompositeParentChildEncoding() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        func jsonString<E: Encodable>(_ value: E) throws -> String { try String(decoding: encoder.encode(value), as: UTF8.self) }
        
        let sysId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, moonId = UUID(), moonJId = #""\#(moonId.uuidString)""#
        let planet = CompositePlanet(name: "A", solarSystemId: sysId, normalizedOrdinal: 1)
        let moon = CompositeMoon(id: moonId, name: "B", planetSolarSystemId: sysId, planetNormalizedOrdinal: 1)
        
        let sysJId = #"{"normalizedOrdinal":1,"solarSystem":{"id":"\#(sysId.uuidString)"}}"#
        let moonJDat = #"{"id":\#(moonJId),"name":"B","orbiting":{"id":\#(sysJId)},"planetoid":{"id":\#(sysJId)},"progenitor":{"id":\#(sysJId)}}"#
        
        // Unloaded children properties
        XCTAssertEqual(try jsonString(planet), #"{"id":\#(sysJId),"name":"A"}"#)
        // Unset optional parent properties
        XCTAssertEqual(try jsonString(moon), #"{"id":\#(moonJId),"name":"B","orbiting":{"id":\#(sysJId)},"planetoid":{"id":null},"progenitor":{"id":null}}"#)

        // OptionalChild loaded as NULL, Children properties loaded empty
        (planet.$moons.value, planet.$moonsMade.value, planet.$fragment.value) = ([], [], .some(.none))
        XCTAssertEqual(try jsonString(planet), #"{"fragment":null,"id":\#(sysJId),"moons":[],"moonsMade":[],"name":"A"}"#)
        
        // Parent unloaded, OptionalParent set with ID and unset/explicit null value respectively
        moon.$orbiting.value = nil
        (moon.$progenitor.id, moon.$progenitor.value) = (planet.id, .none)
        (moon.$planetoid.id, moon.$planetoid.value) = (planet.id, .some(.none))
        XCTAssertEqual(try jsonString(moon), moonJDat)
        
        // Children properties loaded with value(s)
        (planet.$moons.value, planet.$moonsMade.value, planet.$fragment.value) = ([moon], [moon], .some(.some(moon)))
        XCTAssertEqual(try jsonString(planet), #"{"fragment":\#(moonJDat),"id":\#(sysJId),"moons":[\#(moonJDat)],"moonsMade":[\#(moonJDat)],"name":"A"}"#)

        // Parent properties set with IDs and values
        (moon.$orbiting.value, planet.$moons.value) = (planet, nil)
        (moon.$progenitor.value, planet.$moonsMade.value) = (.some(.some(planet)), nil)
        (moon.$planetoid.value, planet.$fragment.value) = (.some(.some(planet)), .none)
        XCTAssertEqual(try jsonString(moon), #"{"id":\#(moonJId),"name":"B","orbiting":{"id":\#(sysJId),"name":"A"},"planetoid":{"id":\#(sysJId),"name":"A"},"progenitor":{"id":\#(sysJId),"name":"A"}}"#)
    }
    
    func testCompositeParentChildDecoding() throws {
        let decoder = JSONDecoder()
        func unjsonString<D: Decodable>(_ json: String, as: D.Type = D.self) throws -> D { try decoder.decode(D.self, from: json.data(using: .utf8)!) }
        
        let sysId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, moonId = UUID(), sysJId = #""\#(sysId.uuidString)""#, moonJId = #""\#(moonId.uuidString)""#
        
        let planet1 = try unjsonString(#"{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}},"name":"A"}"#, as: CompositePlanet.self)
        XCTAssertEqual(planet1.$id.$solarSystem.id, sysId)
        XCTAssertEqual(planet1.id!.normalizedOrdinal, 1)
        XCTAssertEqual(planet1.name, "A")
        XCTAssertNil(planet1.$moons.fromId)
        XCTAssertNil(planet1.$moons.value)
        XCTAssertNil(planet1.$moonsMade.fromId)
        XCTAssertNil(planet1.$moonsMade.value)
        XCTAssertNil(planet1.$fragment.fromId)
        XCTAssertNilNil(planet1.$fragment.value)
        
        let moon1 = try unjsonString(#"{"id":\#(moonJId),"name":"B","orbiting":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}}},"planetoid":{"id":null},"progenitor":{"id":null}}"#, as: CompositeMoon.self)
        XCTAssertEqual(moon1.id, moonId)
        XCTAssertEqual(moon1.name, "B")
        XCTAssertEqual(moon1.$orbiting.id, planet1.id!)
        XCTAssertNil(moon1.$orbiting.value)
        XCTAssertNil(moon1.$progenitor.id)
        XCTAssertNilNil(moon1.$progenitor.value)
        XCTAssertNil(moon1.$planetoid.id)
        XCTAssertNilNil(moon1.$planetoid.value)
        let moon1_1 = try unjsonString(#"{"id":\#(moonJId),"name":"B","orbiting":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}},"name":"A"},"planetoid":{"id":null},"progenitor":{"id":null}}"#, as: CompositeMoon.self)
        XCTAssertNil(moon1_1.$orbiting.value)

        let moon2 = try unjsonString(#"{"id":\#(moonJId),"name":"B","orbiting":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}}},"planetoid":{"id":null},"progenitor":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}}}}"#, as: CompositeMoon.self)
        XCTAssertEqual(moon2.id, moonId)
        XCTAssertEqual(moon2.name, "B")
        XCTAssertEqual(moon2.$orbiting.id, planet1.id!)
        XCTAssertNil(moon2.$orbiting.value)
        XCTAssertEqual(moon2.$progenitor.id, planet1.id!)
        XCTAssertNilNil(moon2.$progenitor.value)
        XCTAssertNil(moon2.$planetoid.id)
        XCTAssertNilNil(moon2.$planetoid.value)
        let moon2_1 = try unjsonString(#"{"id":\#(moonJId),"name":"B","orbiting":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}}},"planetoid":{"id":null},"progenitor":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}},"name":"A"}}"#, as: CompositeMoon.self)
        XCTAssertNilNil(moon2_1.$progenitor.value)

        let moon3 = try unjsonString(#"{"id":\#(moonJId),"name":"B","orbiting":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}}},"planetoid":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}}},"progenitor":{"id":null}}"#, as: CompositeMoon.self)
        XCTAssertEqual(moon3.id, moonId)
        XCTAssertEqual(moon3.name, "B")
        XCTAssertEqual(moon3.$orbiting.id, planet1.id!)
        XCTAssertNil(moon3.$orbiting.value)
        XCTAssertNil(moon3.$progenitor.id)
        XCTAssertNilNil(moon3.$progenitor.value)
        XCTAssertEqual(moon3.$planetoid.id, planet1.id!)
        XCTAssertNilNil(moon3.$planetoid.value)
        let moon3_1 = try unjsonString(#"{"id":\#(moonJId),"name":"B","orbiting":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}}},"planetoid":{"id":{"normalizedOrdinal":1,"solarSystem":{"id":\#(sysJId)}},"name":"A"},"progenitor":{"id":null}}"#, as: CompositeMoon.self)
        XCTAssertNilNil(moon3_1.$planetoid.value)
    }
}

fileprivate func XCTAssertNilNil<V>(_ expression: @autoclosure () throws -> Optional<Optional<V>>, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    func messageIfGiven() -> String { let m = message(); guard !m.isEmpty else { return m }; return " - \(m)" }
    switch Result(catching: { try expression() }) {
    case .success(.none): return
    case .success(.some(.none)): return XCTFail("XCTAssertNilNil failed: \".some(nil)\"\(messageIfGiven())", file: file, line: line)
    case .success(.some(.some(let value))): return XCTFail("XCTAssertNilNil failed: \".some(.some(\(value)))\"\(messageIfGiven())", file: file, line: line)
    case .failure(let error): return XCTFail("XCTAssertNilNil failed: threw error \"\(error)\"\(messageIfGiven())", file: file, line: line)
    }
}

final class PlanetUsingCompositePivot: Model {
    static let schema = Planet.schema
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Parent(key: "star_id") var star: Star
    @Children(for: \.$id.$planet) var planetTags: [CompositePlanetTag]
    @Siblings(through: CompositePlanetTag.self, from: \.$id.$planet, to: \.$id.$tag) var tags: [Tag]
    
    init() {}
    init(id: IDValue? = nil, name: String) { (self.id, self.name) = (id, name) }
    init(id: IDValue? = nil, name: String, starId: UUID) {
        self.id = id
        self.name = name
        self.$star.id = starId
    }
}

final class CompositePlanetTag: Model {
    static let schema = "composite+planet+tag"
    
    final class IDValue: Fields, Hashable {
        @Parent(key: "planet_id") var planet: PlanetUsingCompositePivot
        @Parent(key: "tag_id") var tag: Tag
        
        init() {}
        init(planetID: PlanetUsingCompositePivot.IDValue, tagID: Tag.IDValue) { (self.$planet.id, self.$tag.id) = (planetID, tagID) }
        static func == (lhs: IDValue, rhs: IDValue) -> Bool { lhs.$planet.id == rhs.$planet.id && lhs.$tag.id == rhs.$tag.id }
        func hash(into hasher: inout Hasher) { hasher.combine(self.$planet.id); hasher.combine(self.$tag.id) }
    }
    
    @CompositeID var id: IDValue?
    @Field(key: "notation") var notation: String
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?

    init() {}
    init(planetID: PlanetUsingCompositePivot.IDValue, tagID: Tag.IDValue) { self.id = .init(planetID: planetID, tagID: tagID) }
}

struct CompositePlanetTagMigration: Migration {
    init() {}

    func prepare(on database: Database) -> EventLoopFuture<Void> {
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

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositePlanetTag.schema).delete()
    }
}

final class SolarSystem: Model {
    static let schema = "solar_system"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Children(for: \.$id.$solarSystem) var planets: [CompositePlanet]
    
    init() {}
    init(id: IDValue? = nil, name: String) {
        if let id = id { self.id = id }
        self.name = name
        self.$planets.fromId = self.id
    }
}

final class CompositePlanet: Model {
    static let schema = "composite+planet"
    
    // Note for the curious: "normalized ordinal" means "how many orbits from the center if a unique value was chosen for every planet despite overlapping or shared orbits"
    final class IDValue: Fields, Hashable {
        @Parent(key: "system_id") var solarSystem: SolarSystem
        @Field(key: "nrm_ord") var normalizedOrdinal: Int
        
        init() {}
        init(solarSystemId: SolarSystem.IDValue, normalizedOrdinal: Int) {
            (self.$solarSystem.id, self.normalizedOrdinal) = (solarSystemId, normalizedOrdinal)
        }
        static func ==(lhs: IDValue, rhs: IDValue) -> Bool { lhs.$solarSystem.id == rhs.$solarSystem.id && lhs.normalizedOrdinal == rhs.normalizedOrdinal }
        func hash(into hasher: inout Hasher) { hasher.combine(self.$solarSystem.id); hasher.combine(self.normalizedOrdinal) }
    }
    
    @CompositeID var id: IDValue?
    @Field(key: "name") var name: String
    @CompositeChildren(for: \.$orbiting) var moons: [CompositeMoon]
    @CompositeChildren(for: \.$progenitor) var moonsMade: [CompositeMoon]
    @CompositeOptionalChild(for: \.$planetoid) var fragment: CompositeMoon?
    
    init() {}
    init(name: String, solarSystemId: SolarSystem.IDValue, normalizedOrdinal: Int) {
        self.id = .init(solarSystemId: solarSystemId, normalizedOrdinal: normalizedOrdinal)
        self.name = name
        self.$moons.fromId = self.id
        self.$moonsMade.fromId = self.id
        self.$fragment.fromId = self.id
    }
}

final class CompositeMoon: Model {
    static let schema = "composite+moon"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @CompositeParent(prefix: "planet") var orbiting: CompositePlanet
    @CompositeOptionalParent(prefix: "progenitor", strategy: .camelCase) var progenitor: CompositePlanet?
    @CompositeOptionalParent(prefix: "planetoid") var planetoid: CompositePlanet?
    
    init() {}
    init(id: UUID? = nil, name: String, planetSolarSystemId: SolarSystem.IDValue, planetNormalizedOrdinal: Int, progenitorId: CompositePlanet.IDValue? = nil, planetoidId: CompositePlanet.IDValue? = nil) {
        if let id = id { self.id = id }
        self.name = name
        self.$orbiting.id = .init(solarSystemId: planetSolarSystemId, normalizedOrdinal: planetNormalizedOrdinal)
        if let progenitorId = progenitorId { self.$progenitor.id = progenitorId }
        if let planetoidId = planetoidId { self.$planetoid.id = planetoidId }
    }
}
