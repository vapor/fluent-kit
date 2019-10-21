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
        let dummy = DummyDatabaseForTestSQLSerializer()
        var dbs = Databases()
        dbs.add(dummy, as: .init(string: "dummy"), isDefault: true)
        let db = dbs.default()
    
        _ = try Planet.query(on: db).sort(\.$name, .descending).all().wait()
        XCTAssertEqual(dummy.sqlSerializers.count, 1)
        XCTAssertEqual(dummy.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        dummy.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(\Galaxy.$name, .ascending).all().wait()
        XCTAssertEqual(dummy.sqlSerializers.count, 1)
        XCTAssertEqual(dummy.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."name" ASC"#), true)
        dummy.reset()
        
        _ = try Planet.query(on: db).sort(\.$id, .descending).all().wait()
        XCTAssertEqual(dummy.sqlSerializers.count, 1)
        XCTAssertEqual(dummy.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."id" DESC"#), true)
        dummy.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(\Galaxy.$id, .ascending).all().wait()
        XCTAssertEqual(dummy.sqlSerializers.count, 1)
        XCTAssertEqual(dummy.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."id" ASC"#), true)
        dummy.reset()
        
        _ = try Planet.query(on: db).sort("name", .descending).all().wait()
        XCTAssertEqual(dummy.sqlSerializers.count, 1)
        XCTAssertEqual(dummy.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        dummy.reset()
        
        _ = try Planet.query(on: db).join(\.$galaxy).sort(Galaxy.self, "name", .ascending).all().wait()
        XCTAssertEqual(dummy.sqlSerializers.count, 1)
        XCTAssertEqual(dummy.sqlSerializers.first?.sql.contains(#"ORDER BY "galaxies"."name" ASC"#), true)
        dummy.reset()
    }

    func testSQLSchemaCustom() throws {
        let dummy = DummyDatabaseForTestSQLSerializer()
        var dbs = Databases()
        dbs.add(dummy, as: .init(string: "dummy"), isDefault: true)
        let db = dbs.default()
        
        try db.schema("foo").field(.custom("INDEX i_foo (foo)")).update().wait()
        print(dummy.sqlSerializers)
    }
}
