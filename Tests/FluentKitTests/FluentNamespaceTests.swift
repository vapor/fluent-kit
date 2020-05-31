@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation
import FluentSQL

final class FluentNSTests: XCTestCase {
    func testNameSpaceQuery() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let namespace = ["schema"]
        let p = Planet.schemaOrAlias
        _ = try Planet.query(on: db).all().wait()
        _ = try Planet.query(on: db, in: namespace).all().wait()
            
        XCTAssertEqual(db.sqlSerializers.count, 2)
        
        XCTAssertEqual(db.sqlSerializers[0].sql.contains(#""\#(p)"."id" AS "\#(p)_id""#), true)
        XCTAssertEqual(db.sqlSerializers[0].sql.contains(#"FROM "\#(Planet.schema)" AS "\#(p)""#), true)
        XCTAssertEqual(db.sqlSerializers[1].sql.contains(#""\#(p)"."id" AS "\#(p)_id""#), true)
        XCTAssertEqual(db.sqlSerializers[1].sql.contains(#"FROM "\#(namespace[0])"."\#(Planet.schema)" AS "\#(p)""#), true)
        db.reset()
    }
}
