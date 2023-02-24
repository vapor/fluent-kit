import FluentKit
import XCTest

extension FluentBenchmarker {
    public func testPagination() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            do {
                let planetsPage1 = try Planet.query(on: self.database)
                    .sort(\.$name)
                    .paginate(PageRequest(page: 1, per: 2))
                    .wait()

                XCTAssertEqual(planetsPage1.metadata.page, 1)
                XCTAssertEqual(planetsPage1.metadata.per, 2)
                XCTAssertEqual(planetsPage1.metadata.total, 9)
                XCTAssertEqual(planetsPage1.metadata.pageCount, 5)
                XCTAssertEqual(planetsPage1.items.count, 2)
                XCTAssertEqual(planetsPage1.items[0].name, "Earth")
                XCTAssertEqual(planetsPage1.items[1].name, "Jupiter")
            }
            do {
                let planetsPage2 = try Planet.query(on: self.database)
                    .sort(\.$name)
                    .paginate(PageRequest(page: 2, per: 2))
                    .wait()

                XCTAssertEqual(planetsPage2.metadata.page, 2)
                XCTAssertEqual(planetsPage2.metadata.per, 2)
                XCTAssertEqual(planetsPage2.metadata.total, 9)
                XCTAssertEqual(planetsPage2.metadata.pageCount, 5)
                XCTAssertEqual(planetsPage2.items.count, 2)
                XCTAssertEqual(planetsPage2.items[0].name, "Mars")
                XCTAssertEqual(planetsPage2.items[1].name, "Mercury")
            }
            do {
                let galaxiesPage = try Galaxy.query(on: self.database)
                    .filter(\.$name == "Milky Way")
                    .with(\.$stars)
                    .sort(\.$name)
                    .paginate(PageRequest(page: 1, per: 1))
                    .wait()

                XCTAssertEqual(galaxiesPage.metadata.page, 1)
                XCTAssertEqual(galaxiesPage.metadata.per, 1)

                let milkyWay = galaxiesPage.items[0]
                XCTAssertEqual(milkyWay.name, "Milky Way")
                XCTAssertEqual(milkyWay.stars.count, 2)
            }
        }
    }

    public func testPaginationDoesntCrashWithInvalidValues() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            do {
                _ = try Planet.query(on: self.database)
                    .sort(\.$name)
                    .paginate(PageRequest(page: -1, per: 2))
                    .wait()
            }
            do {
                _ = try Planet.query(on: self.database)
                    .sort(\.$name)
                    .paginate(PageRequest(page: 2, per: -2))
                    .wait()
            }
        }
    }
}
