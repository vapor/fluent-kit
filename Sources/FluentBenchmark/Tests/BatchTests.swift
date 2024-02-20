import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testBatch() throws {
        try self.testBatch_create()
        try self.testBatch_update()
        try self.testBatch_delete()
    }

    private func testBatch_create() throws {
        try runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxies = Array("abcdefghijklmnopqrstuvwxyz").map { letter in
                return Galaxy(name: .init(letter))
            }

            try galaxies.create(on: self.database).wait()
            let count = try Galaxy.query(on: self.database).count().wait()
            XCTAssertEqual(count, 26)
        }
    }

    private func testBatch_update() throws {
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed()
        ]) {
            try Galaxy.query(on: self.database).set(\.$name, to: "Foo")
                .update().wait()

            let galaxies = try Galaxy.query(on: self.database).all().wait()
            for galaxy in galaxies {
                XCTAssertEqual(galaxy.name, "Foo")
            }
        }
    }

    private func testBatch_delete() throws {
        try runTest(#function, [
            GalaxyMigration(),
        ]) {
            let galaxies = Array("abcdefghijklmnopqrstuvwxyz").map { letter in
                return Galaxy(name: .init(letter))
            }
            try EventLoopFuture.andAllSucceed(galaxies.map {
                $0.create(on: self.database)
            }, on: self.database.eventLoop).wait()

            let count = try Galaxy.query(on: self.database).count().wait()
            XCTAssertEqual(count, 26)

            try galaxies[..<5].delete(on: self.database).wait()

            let postDeleteCount = try Galaxy.query(on: self.database).count().wait()
            XCTAssertEqual(postDeleteCount, 21)
        }
    }
}
