import FluentKit
import Foundation
import NIOCore
import XCTest
import Logging

extension FluentBenchmarker {
    public func testEagerLoad() throws {
        try self.testEagerLoad_nesting()
        try self.testEagerLoad_children()
        try self.testEagerLoad_childrenDeleted()
        try self.testEagerLoad_parent()
        try self.testEagerLoad_parentDeleted()
        try self.testEagerLoad_siblings()
        try self.testEagerLoad_siblingsDeleted()
        try self.testEagerLoad_parentJSON()
        try self.testEagerLoad_childrenJSON()
        try self.testEagerLoad_emptyChildren()
        try self.testEagerLoad_throughNilOptionalParent()
        try self.testEagerLoad_throughAllNilOptionalParent()
    }

    private func testEagerLoad_nesting() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars) {
                    $0.with(\.$planets) {
                        $0.with(\.$moons)
                        $0.with(\.$tags)
                    }
                }
                .all().wait()
            self.database.logger.debug(prettyJSON(galaxies))
        }
    }

    private func testEagerLoad_children() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .all().wait()

            for galaxy in galaxies {
                switch galaxy.name {
                case "Milky Way":
                    XCTAssertEqual(
                        galaxy.stars.contains { $0.name == "Sun" },
                        true
                    )
                    XCTAssertEqual(
                        galaxy.stars.contains { $0.name == "Alpheratz"},
                        false
                    )
                default: break
                }
            }
        }
    }
    
    private func testEagerLoad_childrenDeleted() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            try Planet.query(on: self.database).filter(\.$name == "Jupiter").delete().wait()
            
            let sun1 = try XCTUnwrap(Star.query(on: self.database)
                .filter(\.$name == "Sun")
                .with(\.$planets, withDeleted: true)
                .first().wait()
            )
            XCTAssertTrue(sun1.planets.contains { $0.name == "Earth" })
            XCTAssertTrue(sun1.planets.contains { $0.name == "Jupiter" })
            
            let sun2 = try XCTUnwrap(Star.query(on: self.database)
                .filter(\.$name == "Sun")
                .with(\.$planets)
                .first().wait()
            )
            XCTAssertTrue(sun2.planets.contains { $0.name == "Earth" })
            XCTAssertFalse(sun2.planets.contains { $0.name == "Jupiter" })
        }
    }

    private func testEagerLoad_parent() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(planet.star.name, "Sun")
                case "Proxima Centauri b":
                    XCTAssertEqual(planet.star.name, "Alpha Centauri")
                default: break
                }
            }
        }
    }
    
    private func testEagerLoad_parentDeleted() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            try Star.query(on: self.database).filter(\.$name == "Sun").delete().wait()
            
            let planet = try XCTUnwrap(Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .with(\.$star, withDeleted: true)
                .first().wait()
            )
            XCTAssertEqual(planet.star.name, "Sun")
            
            XCTAssertThrowsError(
                try Planet.query(on: self.database)
                    .with(\.$star)
                    .all().wait()
            ) { error in
                guard case let .missingParent(from, to, key, _) = error as? FluentError else {
                    return XCTFail("Unexpected error \(error) thrown")
                }
                XCTAssertEqual(from, "Planet")
                XCTAssertEqual(to, "Star")
                XCTAssertEqual(key, "star_id")
            }
        }
    }

    private func testEagerLoad_siblings() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .with(\.$tags)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(planet.star.name, "Sun")
                    XCTAssertEqual(planet.tags.map { $0.name }.sorted(), ["Inhabited", "Small Rocky"])
                case "Proxima Centauri b":
                    XCTAssertEqual(planet.star.name, "Alpha Centauri")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Small Rocky"])
                case "Jupiter":
                    XCTAssertEqual(planet.star.name, "Sun")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Gas Giant"])
                default: break
                }
            }
        }
    }
    
    private func testEagerLoad_siblingsDeleted() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            try Planet.query(on: self.database).filter(\.$name == "Earth").delete().wait()
            
            let tag1 = try XCTUnwrap(Tag.query(on: self.database)
                .filter(\.$name == "Inhabited")
                .with(\.$planets, withDeleted: true)
                .first().wait()
            )
            XCTAssertEqual(Set(tag1.planets.map(\.name)), ["Earth"])
            
            let tag2 = try XCTUnwrap(Tag.query(on: self.database)
                .filter(\.$name == "Inhabited")
                .with(\.$planets)
                .first().wait()
            )
            XCTAssertEqual(Set(tag2.planets.map(\.name)), [])
        }
    }

    private func testEagerLoad_parentJSON() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .all().wait()
            self.database.logger.debug(prettyJSON(planets))
        }
    }

    private func testEagerLoad_childrenJSON() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .all().wait()
            self.database.logger.debug(prettyJSON(galaxies))
        }
    }

    // https://github.com/vapor/fluent-kit/issues/117
    private func testEagerLoad_emptyChildren() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .filter(\.$name == "foo")
                .with(\.$stars)
                .all().wait()

            XCTAssertEqual(galaxies.count, 0)
        }
    }

    private func testEagerLoad_throughNilOptionalParent() throws {
        try self.runTest(#function, [
            ABCMigration()
        ]) {
            do {
                let c = C()
                try c.create(on: self.database).wait()

                let b = B()
                b.$c.id = c.id!
                try b.create(on: self.database).wait()

                let a = A()
                a.$b.id = b.id
                try a.create(on: self.database).wait()
            }
            do {
                let c = C()
                try c.create(on: self.database).wait()

                let b = B()
                b.$c.id = c.id!
                try b.create(on: self.database).wait()

                let a = A()
                a.$b.id = nil
                try a.create(on: self.database).wait()
            }

            let a = try A.query(on: self.database).with(\.$b) {
                $0.with(\.$c)
            }.all().wait()
            XCTAssertEqual(a.count, 2)
        }
    }

    private func testEagerLoad_throughAllNilOptionalParent() throws {
        try self.runTest(#function, [
            ABCMigration()
        ]) {
            do {
                let c = C()
                try c.create(on: self.database).wait()

                let b = B()
                b.$c.id = c.id!
                try b.create(on: self.database).wait()

                let a = A()
                a.$b.id = nil
                try a.create(on: self.database).wait()
            }

            let a = try A.query(on: self.database).with(\.$b) {
                $0.with(\.$c)
            }.all().wait()
            XCTAssertEqual(a.count, 1)
        }
    }
}

private final class A: Model {
    static let schema = "a"

    @ID
    var id: UUID?

    @OptionalParent(key: "b_id")
    var b: B?

    init() { }
}

private final class B: Model {
    static let schema = "b"

    @ID
    var id: UUID?

    @Parent(key: "c_id")
    var c: C

    init() { }
}

private final class C: Model {
    static let schema = "c"

    @ID
    var id: UUID?

    init() { }
}

private struct ABCMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            database.schema("a").id().field("b_id", .uuid).create(),
            database.schema("b").id().field("c_id", .uuid, .required).create(),
            database.schema("c").id().create(),
        ], on: database.eventLoop)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            database.schema("a").delete(),
            database.schema("b").delete(),
            database.schema("c").delete(),
        ], on: database.eventLoop)
    }
}

func prettyJSON<T>(_ value: T) -> Logger.Message
    where T: Encodable
{
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    return try! .init(stringLiteral: String(decoding: encoder.encode(value), as: UTF8.self))
}
