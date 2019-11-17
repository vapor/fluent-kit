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
        XCTAssertEqual(Planet.key(for: \.$galaxy.$id), "galaxy_id")
    }

    func testGalaxyPlanetSorts() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Planet.query(on: db).sort(\.$name, .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(\Galaxy.$name, .ascending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."name" ASC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).sort(\.$id, .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."id" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(\Galaxy.$id, .ascending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."id" ASC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).sort("name", .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(Galaxy.self, "name", .ascending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."name" ASC"#), true)
        db.reset()
    }

    func testSQLSchemaCustom() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("foo").field(.custom("INDEX i_foo (foo)")).update().wait()
        print(db.sqlSerializers)
        let (driver, db) = Self.dummySQLDb
    
        _ = try Planet.query(on: db).sort(\.$name, .descending).all().wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        driver.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(\Galaxy.$name, .ascending).all().wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."name" ASC"#), true)
        driver.reset()
        
        _ = try Planet.query(on: db).sort(\.$id, .descending).all().wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."id" DESC"#), true)
        driver.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(\Galaxy.$id, .ascending).all().wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."id" ASC"#), true)
        driver.reset()
        
        _ = try Planet.query(on: db).sort("name", .descending).all().wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        driver.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(Galaxy.self, "name", .ascending).all().wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."name" ASC"#), true)
        driver.reset()
    }

    func testSQLSchemaCustom() throws {
        let (driver, db) = Self.dummySQLDb
        
        try db.schema("foo").field(.custom("INDEX i_foo (foo)")).update().wait()
        print(driver.sqlSerializers)
    }
  
    func testRequiredFieldConstraint() throws {
        let (driver, db) = Self.dummySQLDb

        try db.schema("planets")
            .field("id", .int64, .required)
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL)"#)
    }

    func testIdentifierFieldConstraint() throws {
        let (driver, db) = Self.dummySQLDb

        try db.schema("planets")
            .field("id", .int64, .identifier(auto: false))
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY)"#)
        driver.reset()

        try db.schema("planets")
            .field("id", .int64, .identifier(auto: true))
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testForeignKeyFieldConstraint() throws {
        let (driver, db) = Self.dummySQLDb

        try db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id"))
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        driver.reset()

        try db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id", onDelete: .restrict, onUpdate: .cascade))
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
    }

    func testMultipleFieldConstraint() throws {
        let (driver, db) = Self.dummySQLDb

        try db.schema("planets")
            .field("id", .int64, .required, .identifier(auto: true))
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testUniqueTableConstraint() throws {
        let (driver, db) = Self.dummySQLDb

        try db.schema("planets")
            .field("id", .int64)
            .unique(on: "id")
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, CONSTRAINT "uq:id" UNIQUE ("id"))"#)
        driver.reset()

        try db.schema("planets")
            .field("id", .int64)
            .field("name", .string)
            .unique(on: "id", "name")
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, "name" TEXT, CONSTRAINT "uq:id+name" UNIQUE ("id", "name"))"#)
    }

    func testForeignKeyTableConstraint() throws {
        let (driver, db) = Self.dummySQLDb

        try db.schema("planets")
            .field("galaxy_id", .int64)
            .foreignKey("galaxy_id", references: "galaxies", "id")
            .create()
            .wait()
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:galaxy_id+id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        driver.reset()

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
        XCTAssertEqual(driver.sqlSerializers.count, 1)
        XCTAssertEqual(driver.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:galaxy_id+id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
    }
}

// MARK: Helpers

extension FluentKitTests {
    static var dummySQLDb: (driver: DummyDatabaseForTestSQLSerializer, db: Database) {
        let dummy = DummyDatabaseForTestSQLSerializer()
        let dbs = Databases()
        dbs.add(dummy, as: .init(string: "dummy"), isDefault: true)
        return (driver: dummy, db: dbs.default())
    }
}
