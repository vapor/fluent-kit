import FluentKit
import Foundation
import XCTest

public final class FluentBenchmarker {
    public let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    public func testAll() throws {
        try self.testCreate()
        try self.testRead()
        try self.testUpdate()
        try self.testDelete()
        try self.testEagerLoadChildren()
        try self.testEagerLoadParent()
        try self.testEagerLoadParentJoin()
        try self.testEagerLoadSubqueryJSONEncode()
        try self.testEagerLoadJoinJSONEncode()
        try self.testMigrator()
        try self.testMigratorError()
        try self.testJoin()
        try self.testBatchCreate()
        try self.testBatchUpdate()
        try self.testNestedModel()
        try self.testAggregates()
        try self.testIdentifierGeneration()
        try self.testNullifyField()
        try self.testChunkedFetch()
        try self.testUniqueFields()
    }
    
    public func testCreate() throws {
        try self.runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let galaxy = Galaxy()
            galaxy.name.set(to: "Messier 82")
            try galaxy.save(on: self.database).wait()
            guard try galaxy.id.get() == 1 else {
                throw Failure("unexpected galaxy id: \(galaxy)")
            }
            
            guard let fetched = try self.database.query(Galaxy.self).filter(\.name == "Messier 82").first().wait() else {
                throw Failure("unexpected empty result set")
            }
            
            if try fetched.name.get() != galaxy.name.get() {
                throw Failure("unexpected name: \(galaxy) \(fetched)")
            }
            if try fetched.id.get() != galaxy.id.get() {
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
            guard try milkyWay.name.get() == "Milky Way" else {
                throw Failure("unexpected name")
            }
        }
    }
    
    public func testUpdate() throws {
        try runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let galaxy = Galaxy()
            galaxy.name.set(to: "Milkey Way")
            try galaxy.save(on: self.database).wait()
            galaxy.name.set(to: "Milky Way")
            try galaxy.save(on: self.database).wait()
            
            // verify
            let galaxies = try self.database.query(Galaxy.self).filter(\.name == "Milky Way").all().wait()
            guard galaxies.count == 1 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
            guard try galaxies[0].name.get() == "Milky Way" else {
                throw Failure("unexpected galaxy name")
            }
        }
    }
    
    public func testDelete() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
        ]) {
            let galaxy = Galaxy()
            galaxy.name.set(to: "Milky Way")
            try galaxy.save(on: self.database).wait()
            try galaxy.delete(on: self.database).wait()
            
            // verify
            let galaxies = try self.database.query(Galaxy.self).all().wait()
            guard galaxies.count == 0 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
        }
    }
    
    public func testEagerLoadChildren() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let galaxies = try self.database.query(Galaxy.self)
                .with(\.planets)
                .all().wait()

            for galaxy in galaxies {
                let planets = try galaxy.planets.get()
                switch try galaxy.name.get() {
                case "Milky Way":
                    guard try planets.contains(where: { try $0.name.get() == "Earth" }) else {
                        throw Failure("unexpected missing planet")
                    }
                    guard try !planets.contains(where: { try $0.name.get() == "PA-99-N2"}) else {
                        throw Failure("unexpected planet")
                    }
                default: break
                }
            }
        }
    }
    
    public func testEagerLoadParent() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try self.database.query(Planet.self)
                .with(\.galaxy)
                .all().wait()
            
            for planet in planets {
                let galaxy = try planet.galaxy.get()
                switch try planet.name.get() {
                case "Earth":
                    guard try galaxy.name.get() == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(galaxy)")
                    }
                case "PA-99-N2":
                    guard try galaxy.name.get() == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(galaxy)")
                    }
                default: break
                }
            }
        }
    }
    
    public func testEagerLoadParentJoin() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try self.database.query(Planet.self)
                .with(\.galaxy, method: .join)
                .all().wait()
            
            for planet in planets {
                let galaxy = try planet.galaxy.get()
                switch try planet.name.get() {
                case "Earth":
                    guard try galaxy.name.get() == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(galaxy)")
                    }
                case "PA-99-N2":
                    guard try galaxy.name.get() == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(galaxy)")
                    }
                default: break
                }
            }
        }
    }
    
    public func testEagerLoadSubqueryJSONEncode() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try self.database.query(Planet.self)
                .with(\.galaxy, method: .subquery)
                .all().wait()
            
            let encoder = JSONEncoder()
            let json = try encoder.encode(planets)
            let string = String(data: json, encoding: .utf8)!
            
            let expected = """
            [{"id":1,"name":"Mercury","galaxy":{"id":2,"name":"Milky Way"}},{"id":2,"name":"Venus","galaxy":{"id":2,"name":"Milky Way"}},{"id":3,"name":"Earth","galaxy":{"id":2,"name":"Milky Way"}},{"id":4,"name":"Mars","galaxy":{"id":2,"name":"Milky Way"}},{"id":5,"name":"Jupiter","galaxy":{"id":2,"name":"Milky Way"}},{"id":6,"name":"Saturn","galaxy":{"id":2,"name":"Milky Way"}},{"id":7,"name":"Uranus","galaxy":{"id":2,"name":"Milky Way"}},{"id":8,"name":"Neptune","galaxy":{"id":2,"name":"Milky Way"}},{"id":9,"name":"PA-99-N2","galaxy":{"id":1,"name":"Andromeda"}}]
            """
            print(string)
            guard string == expected else {
                throw Failure("unexpected json format")
            }
        }
    }
    
    public func testEagerLoadJoinJSONEncode() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try self.database.query(Planet.self)
                .with(\.galaxy, method: .join)
                .all().wait()
            
            let encoder = JSONEncoder()
            let json = try encoder.encode(planets)
            let string = String(data: json, encoding: .utf8)!
            
            let expected = """
            [{"id":1,"name":"Mercury","galaxy":{"id":2,"name":"Milky Way"}},{"id":2,"name":"Venus","galaxy":{"id":2,"name":"Milky Way"}},{"id":3,"name":"Earth","galaxy":{"id":2,"name":"Milky Way"}},{"id":4,"name":"Mars","galaxy":{"id":2,"name":"Milky Way"}},{"id":5,"name":"Jupiter","galaxy":{"id":2,"name":"Milky Way"}},{"id":6,"name":"Saturn","galaxy":{"id":2,"name":"Milky Way"}},{"id":7,"name":"Uranus","galaxy":{"id":2,"name":"Milky Way"}},{"id":8,"name":"Neptune","galaxy":{"id":2,"name":"Milky Way"}},{"id":9,"name":"PA-99-N2","galaxy":{"id":1,"name":"Andromeda"}}]
            """
            guard string == expected else {
                throw Failure("unexpected json format")
            }
        }
    }
    
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
                .join(\.galaxy)
                .all().wait()
            print(planets)
            for planet in planets {
                let galaxy = planet.joined(Galaxy.self)
                let planetName = try planet.name.get()
                let galaxyName = try galaxy.name.get()
                switch planetName {
                case "Earth":
                    guard galaxyName == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(galaxyName)")
                    }
                case "PA-99-N2":
                    guard galaxyName == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(galaxyName)")
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
                let galaxy = Galaxy()
                galaxy.name.set(to: String(letter))
                return galaxy
            }
                
            try galaxies.create(on: self.database).wait()
            guard try galaxies[5].id.get() == 6 else {
                throw Failure("batch insert did not set id")
            }
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
                
                guard try galaxy.name.get() == "Foo" else {
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
                .filter(\.pet.type == .cat)
                .all().wait()
        
            guard let user = users.first, users.count == 1 else {
                throw Failure("unexpected user count")
            }
            guard try user.name.get() == "Tanner" else {
                throw Failure("unexpected user name")
            }
            guard try user.pet.name.get() == "Ziz" else {
                throw Failure("unexpected pet name")
            }
            guard try user.pet.type.get() == .cat else {
                throw Failure("unexpected pet type")
            }
            
            let encoder = JSONEncoder()
            let json = try encoder.encode(user)
            let string = String(data: json, encoding: .utf8)!
            let expected = """
            {"id":2,"name":"Tanner","pet":{"name":"Ziz","type":"cat"}}
            """
            guard string == expected else {
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
            let galaxy = Galaxy()
            galaxy.name.set(to: "Milky Way")
            guard (try? galaxy.id.get()) == nil else {
                throw Failure("id should not be set")
            }
            try galaxy.save(on: self.database).wait()
            _ = try galaxy.id.get()
            
            
            let a = Galaxy()
            a.name.set(to: "A")
            let b = Galaxy()
            b.name.set(to: "B")
            let c = Galaxy()
            c.name.set(to: "c")
            try a.save(on: self.database).wait()
            try b.save(on: self.database).wait()
            try c.save(on: self.database).wait()
            guard try a.id.get() != b.id.get() && b.id.get() != c.id.get() && a.id.get() != c.id.get() else {
                throw Failure("ids should not be equal")
            }
        }
    }
    
    public func testNullifyField() throws {
        final class Foo: Model {
            var properties: [Property] {
                return [id, bar]
            }
            
            var storage: Storage
        
            var id: Field<Int> {
                return self.id("id")
            }
            
            var bar: Field<String?> {
                return self.field("bar")
            }
            
            init(storage: Storage) {
                self.storage = storage
            }
        }
        try runTest(#function, [
            Foo.autoMigration(),
        ]) {
            let foo = Foo()
            foo.bar.set(to: "test")
            try foo.save(on: self.database).wait()
            guard try foo.bar.get() != nil else {
                throw Failure("unexpected nil value")
            }
            foo.bar.set(to: nil)
            try foo.save(on: self.database).wait()
            guard try foo.bar.get() == nil else {
                throw Failure("unexpected non-nil value")
            }
            
            guard let fetched = try self.database.query(Foo.self)
                .filter(\.id == foo.id.get())
                .first().wait()
            else {
                throw Failure("no model returned")
            }
            guard try fetched.bar.get() == nil else {
                throw Failure("unexpected non-nil value")
            }
        }
    }
    
    public func testChunkedFetch() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
        ]) {
            var fetched64: [Galaxy] = []
            var fetched2047: [Galaxy] = []
            let saves = (1...512).map { i -> EventLoopFuture<Void> in
                let galaxy = Galaxy()
                galaxy.name.set(to: "Milky Way \(i)")
                return galaxy.save(on: self.database)
            }
            try EventLoopFuture<Void>.andAllSucceed(saves, on: self.database.eventLoop).wait()
            
            try self.database.query(Galaxy.self).chunk(max: 64) { chunk in
                guard chunk.count != 0 else {
                    print("[warning] zero length chunk. there is probably an extraneous close happening")
                    return
                }
                guard chunk.count == 64 else {
                    throw Failure("bad chunk count")
                }
                fetched64 += chunk
            }.wait()
            
            guard fetched64.count == 512 else {
                throw Failure("did not fetch all - only \(fetched64.count) out of 512")
            }
            
            try self.database.query(Galaxy.self).chunk(max: 511) { chunk in
                guard chunk.count != 0 else {
                    print("[warning] zero length chunk. there is probably an extraneous close happening")
                    return
                }

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
    
    func testUniqueFields() throws {
        final class Foo: Model {
            var properties: [Property] {
                return [id, bar]
            }
            
            var storage: Storage
            
            var id: Field<Int> {
                return self.id("id")
            }
            
            var bar: Field<String> {
                return self.field("bar")
            }
            
            var baz: Field<Int> {
                return self.field("baz")
            }
            
            convenience init(bar: String, baz: Int) {
                self.init()
                self.bar.set(to: bar)
                self.baz.set(to: baz)
            }
            
            init(storage: Storage) {
                self.storage = storage
            }
        }
        struct FooMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema(Foo.self)
                    .auto()
                    .unique(on: \.bar, \.baz)
                    .create()
            }
            
            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema(Foo.self).delete()
            }
        }
        try runTest(#function, [
            FooMigration(),
        ]) {
            let a1 = Foo(bar: "a", baz: 1)
            try a1.save(on: self.database).wait()
            let a2 = Foo(bar: "a", baz: 2)
            try a2.save(on: self.database).wait()
            do {
                let a1Dup = Foo(bar: "a", baz: 1)
                try a1Dup.save(on: self.database).wait()
                throw Failure("should have failed")
            } catch _ as DatabaseError {
                // pass
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
                self.log("Migration failed, attempting to revert existing...")
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
