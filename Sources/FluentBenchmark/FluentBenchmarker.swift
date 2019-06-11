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
        try self.testEagerLoadParentJSON()
        try self.testEagerLoadChildrenJSON()
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
        try self.testAsyncCreate()
        try self.testSoftDelete()
        try self.testTimestampable()
        try self.testLifecycleHooks()
        try self.testSort()
        try self.testUUIDModel()
    }
    
    public func testCreate() throws {
        try self.runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let galaxy = Galaxy.row()
            galaxy.name = "Messier"
            galaxy.name += " 82"
            try galaxy.save(on: self.database).wait()
            guard galaxy.id == 1 else {
                throw Failure("unexpected galaxy id: \(galaxy)")
            }
            
            guard let fetched = try Galaxy.query(on: self.database)
                .filter(\.name == "Messier 82")
                .first()
                .wait() else {
                    throw Failure("unexpected empty result set")
                }
            
            if fetched.name != galaxy.name {
                throw Failure("unexpected name: \(galaxy) \(fetched)")
            }
            if fetched.id != galaxy.id {
                throw Failure("unexpected id: \(galaxy) \(fetched)")
            }
        }
    }
    
    public func testRead() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            GalaxySeed()
        ]) {
            guard let milkyWay = try Galaxy.query(on: self.database)
                .filter(\.name == "Milky Way")
                .first().wait()
                else {
                    throw Failure("unpexected missing galaxy")
            }
            guard milkyWay.name == "Milky Way" else {
                throw Failure("unexpected name")
            }
        }
    }
    
    public func testUpdate() throws {
        try runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let galaxy = Galaxy.row()
            galaxy.name = "Milkey Way"
            try galaxy.save(on: self.database).wait()
            galaxy.name = "Milky Way"
            try galaxy.save(on: self.database).wait()
            
            // verify
            let galaxies = try Galaxy.query(on: self.database).filter(\.name == "Milky Way").all().wait()
            guard galaxies.count == 1 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
            guard galaxies[0].name == "Milky Way" else {
                throw Failure("unexpected galaxy name")
            }
        }
    }
    
    public func testDelete() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
        ]) {
            let galaxy = Galaxy.row()
            galaxy.name = "Milky Way"
            try galaxy.save(on: self.database).wait()
            try galaxy.delete(on: self.database).wait()
            
            // verify
            let galaxies = try Galaxy.query(on: self.database).all().wait()
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
            let galaxies = try Galaxy.query(on: self.database)
                .eagerLoad(\.planets)
                .all().wait()

            for galaxy in galaxies {
                switch galaxy.name {
                case "Milky Way":
                    guard try galaxy.planets.eagerLoaded().contains(where: { $0.name == "Earth" }) else {
                        throw Failure("unexpected missing planet")
                    }
                    guard try !galaxy.planets.eagerLoaded().contains(where: { $0.name == "PA-99-N2"}) else {
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
            let planets = try Planet.query(on: self.database)
                .eagerLoad(\.galaxy)
                .all().wait()
            
            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard try planet.galaxy.eagerLoaded().name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard try planet.galaxy.eagerLoaded().name == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
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
            let planets = try Planet.query(on: self.database)
                .eagerLoad(\.galaxy, method: .join)
                .all().wait()
            
            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard try planet.galaxy.eagerLoaded().name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard try planet.galaxy.eagerLoaded().name == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                default: break
                }
            }
        }
    }
    
    public func testEagerLoadParentJSON() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            struct PlanetJSON: Codable, Equatable {
                var id: Int
                var name: String
                var galaxy: GalaxyJSON
            }
            struct GalaxyJSON: Codable, Equatable {
                var id: Int
                var name: String
            }

            let milkyWay = GalaxyJSON(id: 2, name: "Milky Way")
            let andromeda = GalaxyJSON(id: 1, name: "Andromeda")
            let expected: [PlanetJSON] = [
                .init(id: 1, name: "Mercury", galaxy: milkyWay),
                .init(id: 2, name: "Venus", galaxy: milkyWay),
                .init(id: 3, name: "Earth", galaxy: milkyWay),
                .init(id: 4, name: "Mars", galaxy: milkyWay),
                .init(id: 5, name: "Jupiter", galaxy: milkyWay),
                .init(id: 6, name: "Saturn", galaxy: milkyWay),
                .init(id: 7, name: "Uranus", galaxy: milkyWay),
                .init(id: 8, name: "Neptune", galaxy: milkyWay),
                .init(id: 9, name: "PA-99-N2", galaxy: andromeda),
            ]

            // subquery
            do {
                let planets = try Planet.query(on: self.database)
                    .eagerLoad(\.galaxy, method: .subquery)
                    .all().wait()

                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
                guard decoded == expected else {
                    throw Failure("unexpected output")
                }
            }

            // join
            do {
                let planets = try Planet.query(on: self.database)
                    .eagerLoad(\.galaxy, method: .join)
                    .all().wait()

                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
                guard decoded == expected else {
                    throw Failure("unexpected output")
                }
            }

        }
    }

    public func testEagerLoadChildrenJSON() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            struct PlanetJSON: Codable, Equatable {
                var id: Int
                var name: String
                var galaxyID: Int
            }
            struct GalaxyJSON: Codable, Equatable {
                var id: Int
                var name: String
                var planets: [PlanetJSON]
            }

            let andromeda = GalaxyJSON(id: 1, name: "Andromeda", planets: [
                .init(id: 9, name: "PA-99-N2", galaxyID: 1),
            ])
            let milkyWay = GalaxyJSON(id: 2, name: "Milky Way", planets: [
                .init(id: 1, name: "Mercury", galaxyID: 2),
                .init(id: 2, name: "Venus", galaxyID: 2),
                .init(id: 3, name: "Earth", galaxyID: 2),
                .init(id: 4, name: "Mars", galaxyID: 2),
                .init(id: 5, name: "Jupiter", galaxyID: 2),
                .init(id: 6, name: "Saturn", galaxyID: 2),
                .init(id: 7, name: "Uranus", galaxyID: 2),
                .init(id: 8, name: "Neptune", galaxyID: 2),
            ])
            let messier82 = GalaxyJSON(id: 3, name: "Messier 82", planets: [])
            let expected: [GalaxyJSON] = [andromeda, milkyWay, messier82]

            let galaxies = try Galaxy.query(on: self.database)
                .eagerLoad(\.planets, method: .subquery)
                .all().wait()

            let decoded = try JSONDecoder().decode([GalaxyJSON].self, from: JSONEncoder().encode(galaxies))
            guard decoded == expected else {
                throw Failure("unexpected output")
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
            
            var migrator = Migrator(
                databases: databases,
                migrations: migrations,
                on: self.database.eventLoop
            )
            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()

            migrator.migrations.add(GalaxySeed())
            try migrator.prepareBatch().wait()

            let logs = try MigrationLog.query(on: self.database).all().wait().map { $0.batch }
            guard logs == [1, 1, 2] else {
                throw Failure("batch did not increment")
            }

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
            let planets = try Planet.query(on: self.database)
                .join(\.galaxy)
                .all().wait()
            for planet in planets {
                let galaxy = try planet.joined(Galaxy.self)
                switch planet.name {
                case "Earth":
                    guard galaxy.name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(galaxy.name)")
                    }
                case "PA-99-N2":
                    guard galaxy.name == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(galaxy.name)")
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
            let galaxies = Array("abcdefghijklmnopqrstuvwxyz").map { letter -> Row<Galaxy> in
                let galaxy = Galaxy.row()
                galaxy.name = .init(letter)
                return galaxy
            }
                
            try galaxies.create(on: self.database).wait()
            let count = try Galaxy.query(on: self.database).count().wait()
            guard count == 26 else {
                throw Failure("Not all galaxies savied")
            }
        }
    }
    
    public func testBatchUpdate() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
            GalaxySeed()
        ]) {
            try Galaxy.query(on: self.database).set(\.name, to: "Foo")
                .update().wait()
            
            let galaxies = try Galaxy.query(on: self.database).all().wait()
            for galaxy in galaxies {
                guard galaxy.name == "Foo" else {
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
            let users = try User.query(on: self.database)
                .filter(\.pet, "type", .equal, User.Pet.Animal.cat)
                .all().wait()
        
            guard let user = users.first, users.count == 1 else {
                throw Failure("unexpected user count")
            }
            guard user.name == "Tanner" else {
                throw Failure("unexpected user name")
            }
            guard user.pet.name == "Ziz" else {
                throw Failure("unexpected pet name")
            }
            guard user.pet.type == .cat else {
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
            let count = try Planet.query(on: self.database)
                .count().wait()
            guard count == 9 else {
                throw Failure("unexpected count: \(count)")
            }
            // filtered w/ results
            let filteredCount = try Planet.query(on: self.database)
                .filter(\.name == "Earth")
                .count().wait()
            guard filteredCount == 1 else {
                throw Failure("unexpected count: \(filteredCount)")
            }
            // filtered empty
            let emptyCount = try Planet.query(on: self.database)
                .filter(\.name == "Pluto")
                .count().wait()
            guard emptyCount == 0 else {
                throw Failure("unexpected count: \(emptyCount)")
            }
            // max id
            let maxID = try Planet.query(on: self.database)
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
            let count = try Planet.query(on: self.database)
                .count().wait()
            guard count == 0 else {
                throw Failure("unexpected count: \(count)")
            }
            // maxid
            let maxID = try Planet.query(on: self.database)
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
            let galaxy = Galaxy.row()
            galaxy.name = "Milky Way"
            guard !galaxy.has(\.id) else {
                throw Failure("id should not be set")
            }
            try galaxy.save(on: self.database).wait()

            let a = Galaxy.row()
            a.name = "A"
            let b = Galaxy.row()
            b.name = "B"
            let c = Galaxy.row()
            c.name = "c"
            try a.save(on: self.database).wait()
            try b.save(on: self.database).wait()
            try c.save(on: self.database).wait()
            guard a.id != b.id && b.id != c.id && a.id != c.id else {
                throw Failure("ids should not be equal")
            }
        }
    }
    
    public func testNullifyField() throws {
        final class Foo: Model {
            static let shared = Foo()
            let id = Field<Int?>("id")
            let bar = Field<String?>("bar")
        }
        try runTest(#function, [
            Foo.autoMigration(),
        ]) {
            let foo = Foo.row()
            foo.bar = "test"
            try foo.save(on: self.database).wait()
            guard foo.bar != nil else {
                throw Failure("unexpected nil value")
            }
            foo.bar = nil
            try foo.save(on: self.database).wait()
            guard foo.bar == nil else {
                throw Failure("unexpected non-nil value")
            }
            
            guard let fetched = try Foo.query(on: self.database)
                .filter(\.id == foo.id)
                .first().wait()
            else {
                throw Failure("no model returned")
            }
            guard fetched.bar == nil else {
                throw Failure("unexpected non-nil value")
            }
        }
    }
    
    public func testChunkedFetch() throws {
        try runTest(#function, [
            Galaxy.autoMigration(),
        ]) {
            var fetched64: [Row<Galaxy>] = []
            var fetched2047: [Row<Galaxy>] = []
            
            try self.database.withConnection { database -> EventLoopFuture<Void> in
                let saves = (1...512).map { i -> EventLoopFuture<Void> in
                    let galaxy = Galaxy.row()
                    galaxy.name = "Milky Way \(i)"
                    return galaxy.save(on: database)
                }
                return .andAllSucceed(saves, on: database.eventLoop)
            }.wait()
            
            try Galaxy.query(on: self.database).chunk(max: 64) { chunk in
                guard chunk.count == 64 else {
                    throw Failure("bad chunk count")
                }
                fetched64 += chunk
            }.wait()
            
            guard fetched64.count == 512 else {
                throw Failure("did not fetch all - only \(fetched64.count) out of 512")
            }
            
            try Galaxy.query(on: self.database).chunk(max: 511) { chunk in
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
    
    public func testUniqueFields() throws {
        final class Foo: Model {
            static let shared = Foo()
            let id = Field<Int?>("id")
            let bar = Field<String>("bar")
            let baz = Field<Int>("baz")
            static func new(bar: String, baz: Int) -> Row<Foo> {
                let new = self.row()
                new.bar = bar
                new.baz = baz
                return new
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
            let a1 = Foo.new(bar: "a", baz: 1)
            try a1.save(on: self.database).wait()
            let a2 = Foo.new(bar: "a", baz: 2)
            try a2.save(on: self.database).wait()
            do {
                let a1Dup = Foo.new(bar: "a", baz: 1)
                try a1Dup.save(on: self.database).wait()
                throw Failure("should have failed")
            } catch _ as DatabaseError {
                // pass
            }
        }
    }

    public func testAsyncCreate() throws {
        try runTest(#function, [
            Galaxy.autoMigration()
        ]) {
            let a = Galaxy.row()
            a.name = "a"
            let b = Galaxy.row()
            b.name = .init("b")
            _ = try a.save(on: self.database).and(b.save(on: self.database)).wait()
            let galaxies = try Galaxy.query(on: self.database).all().wait()
            guard galaxies.count == 2 else {
                throw Failure("both galaxies did not save")
            }
        }
    }

    public func testSoftDelete() throws {
        final class User: Model, SoftDeletable {
            static let shared = User()
            let id = Field<Int?>("id")
            let name = Field<String>("name")
            let deletedAt = Field<Date?>("deletedAt")

            static func new(name: String) -> Row<User> {
                let row = User.row()
                row.name = name
                return row
            }
        }

        func testCounts(allCount: Int, realCount: Int) throws {
            let all = try User.query(on: self.database).all().wait()
            guard all.count == allCount else {
                throw Failure("all count should be \(allCount)")
            }
            let real = try User.query(on: self.database).withSoftDeleted().all().wait()
            guard real.count == realCount else {
                throw Failure("real count should be \(realCount)")
            }
        }

        try runTest(#function, [
            User.autoMigration(),
        ]) {
            // save two users
            try User.new(name: "A").save(on: self.database).wait()
            try User.new(name: "B").save(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            // soft-delete a user
            let a = try User.query(on: self.database).filter(\.name == "A").first().wait()!
            try a.delete(on: self.database).wait()
            try testCounts(allCount: 1, realCount: 2)

            // restore a soft-deleted user
            try a.restore(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            // force-delete a user
            try a.forceDelete(on: self.database).wait()
            try testCounts(allCount: 1, realCount: 1)
        }
    }

    public func testTimestampable() throws {
        final class User: Model, Timestampable {
            static let shared = User()
            let id = Field<Int?>("id")
            let name = Field<String>("name")
            let createdAt = Field<Date?>("createdAt")
            let updatedAt = Field<Date?>("updatedAt")

            static func new(name: String) -> Row<User> {
                let row = User.row()
                row.name = name
                return row
            }
        }

        try runTest(#function, [
            User.autoMigration(),
        ]) {
            let user = User.new(name: "A")
            XCTAssertEqual(user.createdAt, nil)
            XCTAssertEqual(user.updatedAt, nil)
            try user.create(on: self.database).wait()
            XCTAssertNotNil(user.createdAt)
            XCTAssertNotNil(user.updatedAt)
            XCTAssertEqual(user.updatedAt, user.createdAt)
            user.name = "B"
            try user.save(on: self.database).wait()
            XCTAssertNotNil(user.createdAt)
            XCTAssertNotNil(user.updatedAt)
            XCTAssertNotEqual(user.updatedAt, user.createdAt)
        }
    }

    public func testLifecycleHooks() throws {
        struct TestError: Error {
            var string: String
        }
        final class User: Model {
            static let shared = User()
            let id = Field<Int?>("id")
            let name = Field<String>("name")

            func willCreate(_ row: Row<User>, on database: Database) -> EventLoopFuture<Void> {
                row.name = "B"
                return database.eventLoop.makeSucceededFuture(())
            }

            func didCreate(_ row: Row<User>, on database: Database) -> EventLoopFuture<Void> {
                return database.eventLoop.makeFailedFuture(TestError(string: "didCreate"))
            }

            func willUpdate(_ row: Row<User>, on database: Database) -> EventLoopFuture<Void> {
                row.name = "D"
                return database.eventLoop.makeSucceededFuture(())
            }

            func didUpdate(_ row: Row<User>, on database: Database) -> EventLoopFuture<Void> {
                return database.eventLoop.makeFailedFuture(TestError(string: "didUpdate"))
            }

            func willDelete(_ row: Row<User>, on database: Database) -> EventLoopFuture<Void> {
                row.name = "E"
                return database.eventLoop.makeSucceededFuture(())
            }

            func didDelete(_ row: Row<User>, on database: Database) -> EventLoopFuture<Void> {
                return database.eventLoop.makeFailedFuture(TestError(string: "didDelete"))
            }

            static func new(name: String) -> Row<User> {
                let row = User.row()
                row.name = name
                return row
            }
        }

        try runTest(#function, [
            User.autoMigration(),
        ]) {
            let user = User.new(name: "A")

            // create
            do {
                try user.create(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didCreate")
            }
            XCTAssertEqual(user.name, "B")

            // update
            user.name = "C"
            do {
                try user.update(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didUpdate")
            }
            XCTAssertEqual(user.name, "D")

            // delete
            do {
                try user.delete(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didDelete")
            }
            XCTAssertEqual(user.name, "E")
        }
    }

    public func testSort() throws {
        // seeded db
        try runTest(#function, [
            Galaxy.autoMigration(),
            Planet.autoMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let ascending = try Galaxy.query(on: self.database).sort(\.name, .ascending).all().wait()
            let descending = try Galaxy.query(on: self.database).sort(\.name, .descending).all().wait()
            XCTAssertEqual(ascending.map { $0.name }, descending.reversed().map { $0.name })
        }
    }

    public func testUUIDModel() throws {
        struct User: Model {
            static var shared = User()

            let id = Field<UUID?>("id")
            let name = Field<String>("name")
        }
        // seeded db
        try runTest(#function, [
            User.autoMigration(),
        ]) {
            let user = User.row()
            user.name = "Vapor"
            try user.save(on: self.database).wait()

            guard try User.query(on: self.database).count().wait() == 1 else {
                throw Failure("User did not save")
            }
        }
    }

    // MARK: Utilities
    
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
