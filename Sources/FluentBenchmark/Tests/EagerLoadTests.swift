extension FluentBenchmarker {
    public func testEagerLoad() throws {
        try self.testEagerLoad_nesting()
        try self.testEagerLoad_children()
        try self.testEagerLoad_parent()
        try self.testEagerLoad_siblings()
        try self.testEagerLoad_parentJSON()
        try self.testEagerLoad_childrenJSON()
        try self.testEagerLoad_emptyChildren()
        try self.testEagerLoad_throughNilOptionalParent()
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

            try print(prettyJSON(galaxies))
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

    private func testEagerLoad_parentJSON() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .all().wait()

            try print(prettyJSON(planets))
        }
    }

    private func testEagerLoad_childrenJSON() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .all().wait()
            try print(prettyJSON(galaxies))
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

func prettyJSON<T>(_ value: T) throws -> String
    where T: Encodable
{
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    return try String(decoding: encoder.encode(value), as: UTF8.self)
}
