import NIOCore
import XCTest
import FluentKit

extension FluentBenchmarker {
    public func testTransaction() throws {
        try self.testTransaction_basic()
        try self.testTransaction_in()
    }

    private func testTransaction_basic() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let result = self.database.transaction { transaction in
                Star.query(on: transaction)
                    .filter(\.$name == "Sun")
                    .first()
                    .flatMap
                { sun -> EventLoopFuture<Planet> in
                    let pluto = Planet(name: "Pluto")
                    return sun!.$planets.create(pluto, on: transaction).map {
                        pluto
                    }
                }.flatMap { pluto -> EventLoopFuture<(Planet, Tag)> in
                    let tag = Tag(name: "Dwarf")
                    return tag.create(on: transaction).map {
                        (pluto, tag)
                    }
                }.flatMap { (pluto, tag) in
                    tag.$planets.attach(pluto, on: transaction)
                }.flatMapThrowing {
                    throw Test()
                }
            }
            do {
                try result.wait()
            } catch is Test {
                // expected
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            let pluto = try Planet.query(on: self.database)
                .filter(\.$name == "Pluto")
                .first()
                .wait()
            XCTAssertNil(pluto)
        }
    }

    private func testTransaction_in() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            try self.database.transaction { transaction in
                XCTAssertEqual(transaction.inTransaction, true)
                return transaction.transaction { nested in
                    XCTAssertEqual(nested.inTransaction, true)
                    return nested.eventLoop.makeSucceededFuture(())
                }
            }.wait()
        }
    }
}

private struct Test: Error { }
