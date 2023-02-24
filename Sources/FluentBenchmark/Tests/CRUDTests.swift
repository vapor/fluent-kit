import FluentKit
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testCRUD() throws {
        try self.testCRUD_create()
        try self.testCRUD_read()
        try self.testCRUD_update()
        try self.testCRUD_delete()
    }

    private func testCRUD_create() throws {
        try self.runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxy = Galaxy(name: "Messier")
            galaxy.name += " 82"
            try! galaxy.save(on: self.database).wait()
            XCTAssertNotNil(galaxy.id)

            guard let fetched = try Galaxy.query(on: self.database)
                .filter(\.$name == "Messier 82")
                .first()
                .wait()
            else {
                XCTFail("unexpected empty result set")
                return
            }

            if fetched.name != galaxy.name {
                XCTFail("unexpected name: \(galaxy) \(fetched)")
            }
            if fetched.id != galaxy.id {
                XCTFail("unexpected id: \(galaxy) \(fetched)")
            }
        }
    }

    private func testCRUD_read() throws {
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed()
        ]) {
            guard let milkyWay = try Galaxy.query(on: self.database)
                .filter(\.$name == "Milky Way")
                .first().wait()
            else {
                XCTFail("unpexected missing galaxy")
                return
            }
            guard milkyWay.name == "Milky Way" else {
                XCTFail("unexpected name")
                return
            }
        }
    }

    private func testCRUD_update() throws {
        try runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxy = Galaxy(name: "Milkey Way")
            try galaxy.save(on: self.database).wait()
            galaxy.name = "Milky Way"
            try galaxy.save(on: self.database).wait()
            // Test save without changes.
            try galaxy.save(on: self.database).wait()

            // verify
            let galaxies = try Galaxy.query(on: self.database).filter(\.$name == "Milky Way").all().wait()
            guard galaxies.count == 1 else {
                XCTFail("unexpected galaxy count: \(galaxies)")
                return
            }
            guard galaxies[0].name == "Milky Way" else {
                XCTFail("unexpected galaxy name")
                return
            }
        }
    }

    private func testCRUD_delete() throws {
        try runTest(#function, [
            GalaxyMigration(),
        ]) {
            let galaxy = Galaxy(name: "Milky Way")
            try galaxy.save(on: self.database).wait()
            try galaxy.delete(on: self.database).wait()

            // verify
            let galaxies = try Galaxy.query(on: self.database).all().wait()
            guard galaxies.count == 0 else {
                XCTFail("unexpected galaxy count: \(galaxies)")
                return
            }
        }
    }

    public func testAsyncCreate() throws {
        try runTest(#function, [
            GalaxyMigration()
        ]) {
            let a = Galaxy(name: "a")
            let b = Galaxy(name: "b")
            _ = try a.save(on: self.database).and(b.save(on: self.database)).wait()
            let galaxies = try Galaxy.query(on: self.database).all().wait()
            guard galaxies.count == 2 else {
                XCTFail("both galaxies did not save")
                return
            }
        }
    }
}
