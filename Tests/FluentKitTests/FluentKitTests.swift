@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation
import FluentSQL

final class FluentKitTests: XCTestCase {
    func testMigrationLogNames() throws {
        XCTAssertEqual(MigrationLog.key(for: \.$id), "id")
        XCTAssertEqual(MigrationLog.key(for: \.$name), "name")
        XCTAssertEqual(MigrationLog.key(for: \.$batch), "batch")
        XCTAssertEqual(MigrationLog.key(for: \.$createdAt), "created_at")
        XCTAssertEqual(MigrationLog.key(for: \.$updatedAt), "updated_at")
    }

    func testGalaxyPlanetNames() throws {
        XCTAssertEqual(Galaxy.key(for: \.$id), "id")
        XCTAssertEqual(Galaxy.key(for: \.$name), "name")

        XCTAssertEqual(Planet.key(for: \.$id), "id")
        XCTAssertEqual(Planet.key(for: \.$name), "name")
        XCTAssertEqual(Planet.key(for: \.$star.$id), "star_id")
    }

    func testGalaxyPlanetSorts() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Planet.query(on: db).sort(\.$name, .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).join(\.$star).sort(\Star.$name, .ascending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."name" ASC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).sort(\.$id, .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."id" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).join(\.$star).sort(\Star.$id, .ascending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."id" ASC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).sort("name", .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).join(\.$star).sort(Star.self, "name", .ascending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."name" ASC"#), true)
        db.reset()
    }
    
    func testSingleColumnSelect() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        
        _ = try Planet.query(on: db).all(\.$name).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "planets"."name" FROM "planets""#)
        db.reset()
    }
    
    func testSQLDistinct() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        
        _ = try Planet.query(on: db).unique().all(\.$name).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT DISTINCT "planets"."name" FROM "planets""#)
        db.reset()
        
        _ = try Planet.query(on: db).unique().all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.starts(with: #"SELECT DISTINCT "planets"."#), true)
        db.reset()
        
        _ = try? Planet.query(on: db).unique().count(\.$name).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT COUNT(DISTINCT("planets"."name")) AS "fluentAggregate" FROM "planets" LIMIT 1"#)
        db.reset()
        
        _ = try? Planet.query(on: db).unique().sum(\.$id).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT SUM(DISTINCT("planets"."id")) AS "fluentAggregate" FROM "planets" LIMIT 1"#)
        db.reset()
    }

    func testSQLSchemaCustomIndex() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("foo").field(.custom("INDEX i_foo (foo)")).update().wait()
        print(db.sqlSerializers)
    }
  
    func testRequiredFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64, .required)
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL)"#)
    }

    func testIdentifierFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64, .identifier(auto: false))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY)"#)
        db.reset()

        try db.schema("planets")
            .field("id", .int64, .identifier(auto: true))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testForeignKeyFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id"))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        db.reset()

        try db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id", onDelete: .restrict, onUpdate: .cascade))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
    }

    func testMultipleFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64, .required, .identifier(auto: true))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testUniqueTableConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64)
            .unique(on: "id")
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, CONSTRAINT "uq:planets.id" UNIQUE ("id"))"#)
        db.reset()

        try db.schema("planets")
            .field("id", .int64)
            .field("name", .string)
            .unique(on: "id", "name")
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, "name" TEXT, CONSTRAINT "uq:planets.id+planets.name" UNIQUE ("id", "name"))"#)
    }

    func testForeignKeyTableConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("galaxy_id", .int64)
            .foreignKey("galaxy_id", references: "galaxies", "id")
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:planets.galaxy_id+planets.id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        db.reset()

        try db.schema("planets")
            .field("galaxy_id", .int64)
            .foreignKey(
                "galaxy_id",
                references: "galaxies", "id",
                onDelete: .restrict,
                onUpdate: .cascade
            )
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:planets.galaxy_id+planets.id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
    }
    
    func testDecodeWithoutID() throws {
        let json = """
        {"name": "Earth", "moonCount": 1}
        """
        let planet = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
        XCTAssertEqual(planet.id, nil)
        XCTAssertEqual(planet.name, "Earth")
        XCTAssertEqual(planet.nickName, nil)
        XCTAssertEqual(planet.moonCount, 1)
    }
    
    func testDecodeWithID() throws {
        let json = """
        {"id": 42, "name": "Earth", "moonCount": 1}
        """
        let planet = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
        XCTAssertEqual(planet.id, 42)
        XCTAssertEqual(planet.name, "Earth")
        XCTAssertEqual(planet.nickName, nil)
        XCTAssertEqual(planet.moonCount, 1)
    }
    
    func testDecodeWithOptional() throws {
        let json = """
        {"id": 42, "name": "Earth", "moonCount": 1, "nickName": "The Blue Marble"}
        """
        let planet = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
        XCTAssertEqual(planet.id, 42)
        XCTAssertEqual(planet.name, "Earth")
        XCTAssertEqual(planet.nickName, "The Blue Marble")
        XCTAssertEqual(planet.moonCount, 1)
    }
    
    func testDecodeMissingRequired() throws {
        let json = """
        {"name": "Earth"}
        """
        do {
            _ = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
            XCTFail("should have thrown")
        } catch {
            print(error)
        }
    }
    
    func testCreateEmptyModelArrayDoesntQuery() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try [Planet2]().create(on: db).wait()
        XCTAssertEqual(db.sqlSerializers.count, 0)
    }
    
}

final class Planet2: Model {
    static let schema = "planets"
    
    @ID(key: "id")
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "nickname")
    var nickName: String?
    
    @Field(key: "moon_count")
    var moonCount: Int
    
    init() { }
    
    init(id: Int? = nil, name: String, moonCount: Int) {
        self.id = id
        self.name = name
        self.moonCount = moonCount
    }
}
