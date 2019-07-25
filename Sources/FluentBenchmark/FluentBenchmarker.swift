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
            let galaxy = Galaxy(name: "Messier")
            galaxy.name += " 82"
            try galaxy.save(on: self.database).wait()
            guard galaxy.id == 1 else {
                throw Failure("unexpected galaxy id: \(galaxy)")
            }
            print(galaxy)
            
            guard let fetched = try Galaxy.query(on: self.database)
                .filter(\.$name == "Messier 82")
                .first()
                .wait() else {
                    throw Failure("unexpected empty result set")
                }
            print(fetched)
            
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
                .filter(\.$name == "Milky Way")
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
            let galaxy = Galaxy(name: "Milkey Way")
            try galaxy.save(on: self.database).wait()
            galaxy.name = "Milky Way"
            try galaxy.save(on: self.database).wait()
            
            // verify
            let galaxies = try Galaxy.query(on: self.database).filter(\.$name == "Milky Way").all().wait()
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
            let galaxy = Galaxy(name: "Milky Way")
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
                .eagerLoad(\.$planets)
                .all().wait()

            for galaxy in galaxies {
                switch galaxy.name {
                case "Milky Way":
                    guard try galaxy.$planets.eagerLoaded().contains(where: { $0.name == "Earth" }) else {
                        throw Failure("unexpected missing planet")
                    }
                    guard try !galaxy.$planets.eagerLoaded().contains(where: { $0.name == "PA-99-N2"}) else {
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
                .eagerLoad(\.$galaxy)
                .all().wait()
            
            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard try planet.$galaxy.eagerLoaded().name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard try planet.$galaxy.eagerLoaded().name == "Andromeda" else {
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
                .eagerLoad(\.$galaxy, method: .join)
                .all().wait()
            
            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard try planet.$galaxy.eagerLoaded().name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard try planet.$galaxy.eagerLoaded().name == "Andromeda" else {
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
                    .eagerLoad(\.$galaxy, method: .subquery)
                    .all().wait()

                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
                guard decoded == expected else {
                    throw Failure("unexpected output")
                }
            }

            // join
            do {
                let planets = try Planet.query(on: self.database)
                    .eagerLoad(\.$galaxy, method: .join)
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
                struct GalaxyID: Codable, Equatable {
                    var id: Int
                }
                var id: Int
                var name: String
                var galaxy: GalaxyID
            }
            struct GalaxyJSON: Codable, Equatable {
                var id: Int
                var name: String
                var planets: [PlanetJSON]
            }

            let andromeda = GalaxyJSON(id: 1, name: "Andromeda", planets: [
                .init(id: 9, name: "PA-99-N2", galaxy: .init(id: 1)),
            ])
            let milkyWay = GalaxyJSON(id: 2, name: "Milky Way", planets: [
                .init(id: 1, name: "Mercury", galaxy: .init(id: 2)),
                .init(id: 2, name: "Venus", galaxy: .init(id: 2)),
                .init(id: 3, name: "Earth", galaxy: .init(id: 2)),
                .init(id: 4, name: "Mars", galaxy: .init(id: 2)),
                .init(id: 5, name: "Jupiter", galaxy: .init(id: 2)),
                .init(id: 6, name: "Saturn", galaxy: .init(id: 2)),
                .init(id: 7, name: "Uranus", galaxy: .init(id: 2)),
                .init(id: 8, name: "Neptune", galaxy: .init(id: 2)),
            ])
            let messier82 = GalaxyJSON(id: 3, name: "Messier 82", planets: [])
            let expected: [GalaxyJSON] = [andromeda, milkyWay, messier82]

            let galaxies = try Galaxy.query(on: self.database)
                .eagerLoad(\.$planets, method: .subquery)
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
                .join(\.$galaxy)
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
            let galaxies = Array("abcdefghijklmnopqrstuvwxyz").map { letter in
                return Galaxy(name: .init(letter))
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
            try Galaxy.query(on: self.database).set(\.$name, to: "Foo")
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
                .filter(\.$pet, "type", .equal, User.Pet.Animal.cat)
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
                .filter(\.$name == "Earth")
                .count().wait()
            guard filteredCount == 1 else {
                throw Failure("unexpected count: \(filteredCount)")
            }
            // filtered empty
            let emptyCount = try Planet.query(on: self.database)
                .filter(\.$name == "Pluto")
                .count().wait()
            guard emptyCount == 0 else {
                throw Failure("unexpected count: \(emptyCount)")
            }
            // max id
            let maxID = try Planet.query(on: self.database)
                .max(\.$id).wait()
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
                .max(\.$id).wait()
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
            guard galaxy.id == nil else {
                throw Failure("id should not be set")
            }
            try galaxy.save(on: self.database).wait()

            let a = Galaxy(name: "A")
            let b = Galaxy(name: "B")
            let c = Galaxy(name: "C")
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
            @Field("id") var id: Int?
            @Field("bar") var bar: String?

            init() { }

            init(id: Int? = nil, bar: String?) {
                self.id = id
                self.bar = bar
            }
        }
        try runTest(#function, [
            Foo.autoMigration(),
        ]) {
            let foo = Foo(bar: "test")
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
                .filter(\.$id == foo.id)
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
            var fetched64: [Galaxy] = []
            var fetched2047: [Galaxy] = []
            
            try self.database.withConnection { database -> EventLoopFuture<Void> in
                let saves = (1...512).map { i -> EventLoopFuture<Void> in
                    return Galaxy(name: "Milky Way \(i)")
                        .save(on: database)
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
            @Field("id") var id: Int?
            @Field("bar") var bar: String
            @Field("baz") var baz: Int
            init() { }
            init(id: Int? = nil, bar: String, baz: Int) {
                self.id = id
                self.bar = bar
                self.baz = baz
            }
        }
        struct FooMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema(Foo.self)
                    .auto()
                    .unique(on: \.$bar, \.$baz)
                    .create()
            }
            
            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema(Foo.self).delete()
            }
        }
        try runTest(#function, [
            FooMigration(),
        ]) {
            try Foo(bar: "a", baz: 1).save(on: self.database).wait()
            try Foo(bar: "a", baz: 2).save(on: self.database).wait()
            do {
                try Foo(bar: "a", baz: 1).save(on: self.database).wait()
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
            let a = Galaxy(name: "a")
            let b = Galaxy(name: "b")
            _ = try a.save(on: self.database).and(b.save(on: self.database)).wait()
            let galaxies = try Galaxy.query(on: self.database).all().wait()
            guard galaxies.count == 2 else {
                throw Failure("both galaxies did not save")
            }
        }
    }

    public func testSoftDelete() throws {
        final class User: Model, SoftDeletable {
            @Field("id") var id: Int?
            @Field("name") var name: String
            @Field("deleted_at") var deletedAt: Date?
            init() { }
            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
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
            try User(name: "A").save(on: self.database).wait()
            try User(name: "B").save(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            // soft-delete a user
            let a = try User.query(on: self.database).filter(\.$name == "A").first().wait()!
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
            @Field("id") var id: Int?
            @Field("name") var name: String
            @Field("created_at") var createdAt: Date?
            @Field("updated_at") var updatedAt: Date?

            init() { }

            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
                self.createdAt = nil
                self.updatedAt = nil
            }
        }

        try runTest(#function, [
            User.autoMigration(),
        ]) {
            let user = User(name: "A")
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
            @Field("id") var id: Int?
            @Field("name") var name: String

            init() { }

            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
            }

            func willCreate(on database: Database) -> EventLoopFuture<Void> {
                self.name = "B"
                return database.eventLoop.makeSucceededFuture(())
            }

            func didCreate(on database: Database) -> EventLoopFuture<Void> {
                return database.eventLoop.makeFailedFuture(TestError(string: "didCreate"))
            }

            func willUpdate(on database: Database) -> EventLoopFuture<Void> {
                self.name = "D"
                return database.eventLoop.makeSucceededFuture(())
            }

            func didUpdate(on database: Database) -> EventLoopFuture<Void> {
                return database.eventLoop.makeFailedFuture(TestError(string: "didUpdate"))
            }

            func willDelete(on database: Database) -> EventLoopFuture<Void> {
                self.name = "E"
                return database.eventLoop.makeSucceededFuture(())
            }

            func didDelete(on database: Database) -> EventLoopFuture<Void> {
                return database.eventLoop.makeFailedFuture(TestError(string: "didDelete"))
            }
        }

        try runTest(#function, [
            User.autoMigration(),
        ]) {
            let user = User(name: "A")
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
            let ascending = try Galaxy.query(on: self.database).sort(\.$name, .ascending).all().wait()
            let descending = try Galaxy.query(on: self.database).sort(\.$name, .descending).all().wait()
            XCTAssertEqual(ascending.map { $0.name }, descending.reversed().map { $0.name })
        }
    }

    public func testUUIDModel() throws {
        final class User: Model {
            @Field("id") var id: UUID?
            @Field("name") var name: String

            init() { }

            init(id: UUID? = nil, name: String) {
                self.id = id
                self.name = name
            }
        }
        // seeded db
        try runTest(#function, [
            User.autoMigration(),
        ]) {
            try User(name: "Vapor")
                .save(on: self.database).wait()
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
