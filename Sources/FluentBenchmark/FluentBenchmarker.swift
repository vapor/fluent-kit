import FluentKit
import Foundation
import XCTest

public final class FluentBenchmarker {
    public let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    public func testAll() throws {
//        try self.testCreate()
//        try self.testRead()
//        try self.testUpdate()
//        try self.testDelete()
//        try self.testEagerLoadChildren()
//        try self.testEagerLoadParent()
//        try self.testEagerLoadParentJoin()
//        try self.testEagerLoadJSON()
//        try self.testMigrator()
//        try self.testMigratorError()
//        try self.testJoin()
//        try self.testBatchCreate()
//        try self.testBatchUpdate()
//        try self.testNestedModel()
//        try self.testAggregates()
//        try self.testIdentifierGeneration()
//        try self.testNullifyField()
//        try self.testChunkedFetch()
//        try self.testUniqueFields()
//        try self.testAsyncCreate()
    }
    
    public func testCreate() throws {
        try self.runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let galaxy = Galaxy(name: "Messier")
            galaxy.name.value += " 82"
            try galaxy.save(on: self.database).wait()
            guard galaxy.id.value == 1 else {
                throw Failure("unexpected galaxy id: \(galaxy)")
            }
            
            guard let fetched = try self.database.query(Galaxy.self).filter(\.name == "Messier 82").first().wait() else {
                throw Failure("unexpected empty result set")
            }
            
            if fetched.name.value != galaxy.name.value {
                throw Failure("unexpected name: \(galaxy) \(fetched)")
            }
            if fetched.id.value != galaxy.id.value {
                throw Failure("unexpected id: \(galaxy) \(fetched)")
            }
        }
    }
    
    public func testRead() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            GalaxySeed()
        ]) {
            guard let milkyWay = try self.database.query(Galaxy.self)
                .filter(\.name == "Milky Way")
                .first().wait()
                else {
                    throw Failure("unpexected missing galaxy")
            }
            guard milkyWay.name.value == "Milky Way" else {
                throw Failure("unexpected name")
            }
        }
    }
    
    public func testUpdate() throws {
        try runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let galaxy = Galaxy(name: "Milkey Way")
            try galaxy.save(on: self.database).wait()
            galaxy.name.value = "Milky Way"
            try galaxy.save(on: self.database).wait()
            
            // verify
            let galaxies = try self.database.query(Galaxy.self).filter(\.name == "Milky Way").all().wait()
            guard galaxies.count == 1 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
            guard galaxies[0].name.value == "Milky Way" else {
                throw Failure("unexpected galaxy name")
            }
        }
    }
    
    public func testDelete() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
        ]) {
            let galaxy = Galaxy(name: "Milky Way")
            try galaxy.save(on: self.database).wait()
            try galaxy.delete(on: self.database).wait()
            
            // verify
            let galaxies = try self.database.query(Galaxy.self).all().wait()
            guard galaxies.count == 0 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
        }
    }
    
//    public func testEagerLoadChildren() throws {
//        try runTest(#function, [
//            Galaxy.autoMigration(),
//            Planet.autoMigration(),
//            GalaxySeed(),
//            PlanetSeed()
//        ]) {
//            let galaxies = try self.database.query(Galaxy.self)
//                .with(\.planets)
//                .all().wait()
//
//            for galaxy in galaxies {
//                let planets = try galaxy.get(\.planets)
//                switch try galaxy.get(\.name) {
//                case "Milky Way":
//                    guard try planets.contains(where: { try $0.get(\.name) == "Earth" }) else {
//                        throw Failure("unexpected missing planet")
//                    }
//                    guard try !planets.contains(where: { try $0.get(\.name) == "PA-99-N2"}) else {
//                        throw Failure("unexpected planet")
//                    }
//                default: break
//                }
//            }
//        }
//    }
//    
//    public func testEagerLoadParent() throws {
//        try runTest(#function, [
//            Galaxy.autoMigration(),
//            Planet.autoMigration(),
//            GalaxySeed(),
//            PlanetSeed()
//        ]) {
//            let planets = try self.database.query(Planet.self)
//                .with(\.galaxy)
//                .all().wait()
//            
//            for planet in planets {
//                let galaxy = try planet.get(\.galaxy)
//                switch try planet.get(\.name) {
//                case "Earth":
//                    guard try galaxy.get(\.name) == "Milky Way" else {
//                        throw Failure("unexpected galaxy name: \(galaxy)")
//                    }
//                case "PA-99-N2":
//                    guard try galaxy.get(\.name) == "Andromeda" else {
//                        throw Failure("unexpected galaxy name: \(galaxy)")
//                    }
//                default: break
//                }
//            }
//        }
//    }
//    
//    public func testEagerLoadParentJoin() throws {
//        try runTest(#function, [
//            Galaxy.autoMigration(),
//            Planet.autoMigration(),
//            GalaxySeed(),
//            PlanetSeed()
//        ]) {
//            let planets = try self.database.query(Planet.self)
//                .with(\.galaxy, method: .join)
//                .all().wait()
//            
//            for planet in planets {
//                let galaxy = try planet.get(\.galaxy)
//                switch try planet.get(\.name) {
//                case "Earth":
//                    guard try galaxy.get(\.name) == "Milky Way" else {
//                        throw Failure("unexpected galaxy name: \(galaxy)")
//                    }
//                case "PA-99-N2":
//                    guard try galaxy.get(\.name) == "Andromeda" else {
//                        throw Failure("unexpected galaxy name: \(galaxy)")
//                    }
//                default: break
//                }
//            }
//        }
//    }
//    
//    public func testEagerLoadJSON() throws {
//        try runTest(#function, [
//            Galaxy.autoMigration(),
//            Planet.autoMigration(),
//            GalaxySeed(),
//            PlanetSeed()
//        ]) {
//            struct PlanetJSON: Codable, Equatable {
//                var id: Int
//                var name: String
//                var galaxy: GalaxyJSON
//            }
//            struct GalaxyJSON: Codable, Equatable {
//                var id: Int
//                var name: String
//            }
//
//            let milkyWay = GalaxyJSON(id: 2, name: "Milky Way")
//            let andromeda = GalaxyJSON(id: 1, name: "Andromeda")
//            let expected: [PlanetJSON] = [
//                .init(id: 1, name: "Mercury", galaxy: milkyWay),
//                .init(id: 2, name: "Venus", galaxy: milkyWay),
//                .init(id: 3, name: "Earth", galaxy: milkyWay),
//                .init(id: 4, name: "Mars", galaxy: milkyWay),
//                .init(id: 5, name: "Jupiter", galaxy: milkyWay),
//                .init(id: 6, name: "Saturn", galaxy: milkyWay),
//                .init(id: 7, name: "Uranus", galaxy: milkyWay),
//                .init(id: 8, name: "Neptune", galaxy: milkyWay),
//                .init(id: 9, name: "PA-99-N2", galaxy: andromeda),
//            ]
//
//            // subquery
//            do {
//                let planets = try self.database.query(Planet.self)
//                    .with(\.galaxy, method: .subquery)
//                    .all().wait()
//
//                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
//                guard decoded == expected else {
//                    throw Failure("unexpected output")
//                }
//            }
//
//            // join
//            do {
//                let planets = try self.database.query(Planet.self)
//                    .with(\.galaxy, method: .join)
//                    .all().wait()
//
//                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
//                guard decoded == expected else {
//                    throw Failure("unexpected output")
//                }
//            }
//
//        }
//    }
    
    public func testMigrator() throws {
        try self.runTest(#function, []) {
            var migrations = Migrations()
            migrations.add(Galaxy.autoMigration())
            migrations.add(Planet.autoMigration())
            
            var databases = Databases(on: self.database.eventLoop)
            databases.add(self.database, as: .init(string: "main"))
            
            let migrator = Migrator(
                databases: databases,
                migrations: migrations,
                on: self.database.eventLoop
            )
            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()
            try migrator.revertAllBatches().wait()
            
        }
    }
    
    public func testMigratorError() throws {
        try self.runTest(#function, []) {
            var migrations = Migrations()
            migrations.add(Galaxy.autoMigration())
            migrations.add(ErrorMigration())
            migrations.add(Planet.autoMigration())
            
            var databases = Databases(on: self.database.eventLoop)
            databases.add(self.database, as: .init(string: "main"))
            
            let migrator = Migrator(
                databases: databases,
                migrations: migrations,
                on: self.database.eventLoop
            )
            try migrator.setupIfNeeded().wait()
            do {
                try migrator.prepareBatch().wait()
                throw Failure("prepare did not fail")
            } catch {
                // success
                self.log("Migration failed: \(error)")
            }
            try migrator.revertAllBatches().wait()
        }
    }
    
    public func testJoin() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try self.database.query(Planet.self)
                .join(\Galaxy.id, to: \Planet.galaxy.id)
                .all().wait()
            for planet in planets {
                #warning("TODO: fixme")
                let galaxy: Galaxy! = nil
                switch planet.name.value {
                case "Earth":
                    guard galaxy.name.value == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(galaxy.name.value)")
                    }
                case "PA-99-N2":
                    guard galaxy.name.value == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(galaxy.name.value)")
                    }
                default: break
                }
            }
        }
    }
    
    public func testBatchCreate() throws {
        try runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let galaxies = Array("abcdefghijklmnopqrstuvwxyz").map { letter -> Galaxy in
                return Galaxy(name: String(letter))
            }
                
            try self.database.create(galaxies).wait()
            #warning("TODO: mysql cannot support this")
//            guard try galaxies[5].get(\.id) == 6 else {
//                throw Failure("batch insert did not set id")
//            }
        }
    }
    
    public func testBatchUpdate() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            GalaxySeed()
        ]) {
            try self.database.query(Galaxy.self).set(\.name, to: "Foo")
                .update().wait()
            
            let galaxies = try self.database.query(Galaxy.self).all().wait()
            for galaxy in galaxies {
                guard galaxy.name.value == "Foo" else {
                    throw Failure("batch update did not set id")
                }
            }
        }
    }
    
    public func testNestedModel() throws {
        try runTest(#function, [
            User.autoMigration(),
            UserSeed()
        ]) {
            let users = try self.database.query(User.self)
                .filter(\.pet, "type", .equals, User.Pet.Animal.cat)
                .all().wait()
        
            guard let user = users.first, users.count == 1 else {
                throw Failure("unexpected user count")
            }
            guard user.name.value == "Tanner" else {
                throw Failure("unexpected user name")
            }
            guard user.pet.value.name == "Ziz" else {
                throw Failure("unexpected pet name")
            }
            guard user.pet.value.type == .cat else {
                throw Failure("unexpected pet type")
            }

            struct UserJSON: Equatable, Codable {
                var id: Int
                var name: String
                var pet: PetJSON
            }
            struct PetJSON: Equatable, Codable {
                var name: String
                var type: String
            }
            // {"id":2,"name":"Tanner","pet":{"name":"Ziz","type":"cat"}}
            let expected = UserJSON(id: 2, name: "Tanner", pet: .init(name: "Ziz", type: "cat"))

            let decoded = try JSONDecoder().decode(UserJSON.self, from: JSONEncoder().encode(user))
            guard decoded == expected else {
                throw Failure("unexpected output")
            }
        }
    }
    
    public func testAggregates() throws {
        // seeded db
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            // whole table
            let count = try self.database.query(Planet.self)
                .count().wait()
            guard count == 9 else {
                throw Failure("unexpected count: \(count)")
            }
            // filtered w/ results
            let filteredCount = try self.database.query(Planet.self)
                .filter(\.name == "Earth")
                .count().wait()
            guard filteredCount == 1 else {
                throw Failure("unexpected count: \(filteredCount)")
            }
            // filtered empty
            let emptyCount = try self.database.query(Planet.self)
                .filter(\.name == "Pluto")
                .count().wait()
            guard emptyCount == 0 else {
                throw Failure("unexpected count: \(emptyCount)")
            }
            // max id
            let maxID = try self.database.query(Planet.self)
                .max(\.id).wait()
            guard maxID == 9 else {
                throw Failure("unexpected maxID: \(maxID ?? -1)")
            }
        }
        // empty db
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
        ]) {
            // whole table
            let count = try self.database.query(Planet.self)
                .count().wait()
            guard count == 0 else {
                throw Failure("unexpected count: \(count)")
            }
            // maxid
            let maxID = try self.database.query(Planet.self)
                .max(\.id).wait()
            guard maxID == nil else {
                throw Failure("unexpected maxID: \(maxID!)")
            }
        }
    }
    
    public func testIdentifierGeneration() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
        ]) {
            let galaxy = Galaxy(name: "Milky Way")
            try galaxy.save(on: self.database).wait()
            guard galaxy.id.value == 1 else {
                throw Failure("should have set id")
            }
            
            let a = Galaxy(name: "A")
            let b = Galaxy(name: "B")
            let c = Galaxy(name: "C")
            try a.save(on: self.database).wait()
            try b.save(on: self.database).wait()
            try c.save(on: self.database).wait()
            guard a.id.value != b.id.value && b.id.value != c.id.value && a.id.value != c.id.value else {
                throw Failure("ids should not be equal")
            }
        }
    }
    
//    public func testNullifyField() throws {
//        final class Foo: Model {
//            static let `default` = Foo()
//            let id = Field<Int>()
//            let bar = Field<String?>()
//        }
//        try runTest(#function, [
//            Foo.autoMigration(),
//        ]) {
//            let foo = Foo.new()
//            foo.set(\.bar, to: "test")
//            try foo.save(on: self.database).wait()
//            guard try foo.get(\.bar) != nil else {
//                throw Failure("unexpected nil value")
//            }
//            foo.set(\.bar, to: nil)
//            try foo.save(on: self.database).wait()
//            guard try foo.get(\.bar) == nil else {
//                throw Failure("unexpected non-nil value")
//            }
//
//            guard let fetched = try self.database.query(Foo.self)
//                .filter(\.id == foo.get(\.id))
//                .first().wait()
//            else {
//                throw Failure("no model returned")
//            }
//            guard try fetched.get(\.bar) == nil else {
//                throw Failure("unexpected non-nil value")
//            }
//        }
//    }

    public func testChunkedFetch() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
        ]) {
            var fetched64: [Galaxy] = []
            var fetched2047: [Galaxy] = []
            
            try self.database.transaction { database -> EventLoopFuture<Void> in
                let saves = (1...512).map { i -> EventLoopFuture<Void> in
                    return Galaxy(name: "Milky Way \(i)")
                        .save(on: database)
                }
                return .andAllSucceed(saves, on: database.eventLoop)
            }.wait()
            
            try self.database.query(Galaxy.self).chunk(max: 64) { chunk in
                guard chunk.count == 64 else {
                    throw Failure("bad chunk count")
                }
                fetched64 += chunk
            }.wait()
            
            guard fetched64.count == 512 else {
                throw Failure("did not fetch all - only \(fetched64.count) out of 512")
            }
            
            try self.database.query(Galaxy.self).chunk(max: 511) { chunk in
                guard chunk.count == 511 || chunk.count == 1 else {
                    throw Failure("bad chunk count")
                }
                fetched2047 += chunk
            }.wait()
            
            guard fetched2047.count == 512 else {
                throw Failure("did not fetch all - only \(fetched2047.count) out of 512")
            }
        }
    }
    
//    public func testUniqueFields() throws {
//        final class Foo: Model {
//            static let `default` = Foo()
//            let id = Field<Int>("id")
//            let bar = Field<String>("bar")
//            let baz = Field<Int>("baz")
//            static func new(bar: String, baz: Int) -> Row {
//                let new = self.new()
//                new.set(\.bar, to: bar)
//                new.set(\.baz, to: baz)
//                return new
//            }
//        }
//        struct FooMigration: Migration {
//            func prepare(on database: Database) -> EventLoopFuture<Void> {
//                return database.schema(Foo.self)
//                    .auto()
//                    .unique(on: \.bar, \.baz)
//                    .create()
//            }
//
//            func revert(on database: Database) -> EventLoopFuture<Void> {
//                return database.schema(Foo.self).delete()
//            }
//        }
//        try runTest(#function, [
//            FooMigration(),
//        ]) {
//            let a1 = Foo.new(bar: "a", baz: 1)
//            try a1.save(on: self.database).wait()
//            let a2 = Foo.new(bar: "a", baz: 2)
//            try a2.save(on: self.database).wait()
//            do {
//                let a1Dup = Foo.new(bar: "a", baz: 1)
//                try a1Dup.save(on: self.database).wait()
//                throw Failure("should have failed")
//            } catch _ as DatabaseError {
//                // pass
//            }
//        }
//    }

    public func testAsyncCreate() throws {
        try runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let a = Galaxy(name: "A")
            let b = Galaxy(name: "B")
            _ = try a.save(on: self.database).and(b.save(on: self.database)).wait()
            let galaxies = try self.database.query(Galaxy.self).all().wait()
            guard galaxies.count == 2 else {
                throw Failure("both galaxies did not save")
            }
        }
    }
    
    struct Failure: Error {
        let reason: String
        let line: UInt
        let file: StaticString
        
        init(_ reason: String, line: UInt = #line, file: StaticString = #file) {
            self.reason = reason
            self.line = line
            self.file = file
        }
    }
    
    private func runTest(_ name: String, _ migrations: [Migration], _ test: () throws -> ()) throws {
        self.log("Running \(name)...")
        for migration in migrations {
            do {
                try migration.prepare(on: self.database).wait()
            } catch {
                self.log("Migration failed: \(error) ")
                self.log("Attempting to revert existing migrations...")
                try migration.revert(on: self.database).wait()
                try migration.prepare(on: self.database).wait()
            }
        }
        var e: Error?
        do {
            try test()
        } catch let failure as Failure {
            XCTFail(failure.reason, file: failure.file, line: failure.line)
        } catch {
            e = error
        }
        for migration in migrations {
            try migration.revert(on: self.database).wait()
        }
        if let error = e {
            throw error
        }
    }
    
    private func log(_ message: String) {
        print("[FluentBenchmark] \(message)")
    }
}
