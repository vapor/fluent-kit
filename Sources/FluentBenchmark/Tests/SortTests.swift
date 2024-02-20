import FluentSQL
import XCTest
import SQLKit

extension FluentBenchmarker {
    public func testSort(sql: Bool = true) throws {
        try self.testSort_basic()
        if sql {
            try self.testSort_sql()
            try self.testSort_embedSql()
        }
    }

    private func testSort_basic() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let ascending = try Galaxy.query(on: self.database)
                .sort(\.$name, .ascending)
                .all().wait()
            let descending = try Galaxy.query(on: self.database)
                .sort(\.$name, .descending)
                .all().wait()
            XCTAssertEqual(
                ascending.map(\.name),
                descending.reversed().map(\.name)
            )
        }
    }

    private func testSort_sql() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .sort(.sql("name", .notEqual, "Earth"))
                .all().wait()
            XCTAssertEqual(planets.first?.name, "Earth")
        }
    }

    private func testSort_embedSql() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .sort(.sql(embed: "\(ident: "name")\(SQLBinaryOperator.notEqual)\(literal: "Earth")"))
                .all().wait()
            XCTAssertEqual(planets.first?.name, "Earth")
        }
    }
}
