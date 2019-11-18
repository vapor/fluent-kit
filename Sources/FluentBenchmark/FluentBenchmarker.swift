@testable import FluentKit
import Foundation
import NIO
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
        try self.testModelMiddleware()
        try self.testSort()
        try self.testUUIDModel()
        try self.testNewModelDecode()
        try self.testSiblingsAttach()
        try self.testSiblingsEagerLoad()
        try self.testParentGet()
        try self.testParentSerialization()
        try self.testMultipleJoinSameTable()
        try self.testOptionalParent()
        try self.testFieldFilter()
        try self.testJoinedFieldFilter()
    }
    
    public func testCreate() throws {
        try self.runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxy = Galaxy(name: "Messier")
            galaxy.name += " 82"
            try galaxy.save(on: self.database).wait()
            guard galaxy.id == 1 else {
                throw Failure("unexpected galaxy id: \(galaxy)")
            }
            
            guard let fetched = try Galaxy.query(on: self.database)
                .filter(\.$name == "Messier 82")
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
            GalaxyMigration(),
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
            GalaxyMigration()
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
            GalaxyMigration(),
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
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$planets)
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
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$galaxy)
                .all().wait()
            
            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard planet.galaxy.name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard planet.galaxy.name == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                default: break
                }
            }
        }
    }
    
    public func testEagerLoadParentJoin() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$galaxy)
                .all().wait()
            
            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard planet.galaxy.name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard planet.galaxy.name == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                default: break
                }
            }
        }
    }
    
    public func testEagerLoadParentJSON() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
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
                    .with(\.$galaxy)
                    .all().wait()

                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
                guard decoded == expected else {
                    throw Failure("unexpected output")
                }
            }

            // join
            do {
                let planets = try Planet.query(on: self.database)
                    .with(\.$galaxy)
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
            GalaxyMigration(),
            PlanetMigration(),
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
                .with(\.$planets)
                .all().wait()

            let decoded = try JSONDecoder().decode([GalaxyJSON].self, from: JSONEncoder().encode(galaxies))
            guard decoded == expected else {
                throw Failure("unexpected output")
            }
        }
    }
    
    public func testMigrator() throws {
        try self.runTest(#function, []) {
            let migrations = Migrations()
            migrations.add(GalaxyMigration())
            migrations.add(PlanetMigration())
            
            let migrator = Migrator(
                databaseFactory: { _ in self.database },
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
            let migrations = Migrations()
            migrations.add(GalaxyMigration())
            migrations.add(ErrorMigration())
            migrations.add(PlanetMigration())
            
            let migrator = Migrator(
                databaseFactory: { _ in self.database },
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
            GalaxyMigration(),
            PlanetMigration(),
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
            GalaxyMigration()
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
            GalaxyMigration(),
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
            UserMigration(),
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
            GalaxyMigration(),
            PlanetMigration(),
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
                throw Failure("unexpected maxID: \(maxID ?? 0)")
            }
        }
        // empty db
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
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
            // expect error?
            guard maxID == nil else {
                throw Failure("unexpected maxID: \(maxID!)")
            }
        }
    }
    
    public func testIdentifierGeneration() throws {
        try runTest(#function, [
            GalaxyMigration(),
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
            static let schema = "foos"

            @ID(key: "id")
            var id: Int?

            @Field(key: "bar")
            var bar: String?

            init() { }

            init(id: Int? = nil, bar: String?) {
                self.id = id
                self.bar = bar
            }
        }
        struct FooMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos")
                    .field("id", .int, .identifier(auto: true))
                    .field("bar", .string)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos").delete()
            }
        }
        try runTest(#function, [
            FooMigration(),
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
                .filter(\.$id == foo.id!)
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
            GalaxyMigration(),
        ]) {
            var fetched64: [Result<Galaxy, Error>] = []
            var fetched2047: [Result<Galaxy, Error>] = []
            
            let saves = (1...512).map { i -> EventLoopFuture<Void> in
                return Galaxy(name: "Milky Way \(i)")
                    .save(on: self.database)
            }
            try EventLoopFuture<Void>.andAllSucceed(saves, on: self.database.eventLoop).wait()
            
            try Galaxy.query(on: self.database).chunk(max: 64) { chunk in
                guard chunk.count == 64 else {
                    XCTFail("bad chunk count")
                    return
                }
                fetched64 += chunk
            }.wait()
            
            guard fetched64.count == 512 else {
                throw Failure("did not fetch all - only \(fetched64.count) out of 512")
            }
            
            try Galaxy.query(on: self.database).chunk(max: 511) { chunk in
                guard chunk.count == 511 || chunk.count == 1 else {
                    XCTFail("bad chunk count")
                    return
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
            static let schema = "foos"

            @ID(key: "id")
            var id: Int?

            @Field(key: "bar")
            var bar: String

            @Field(key: "baz")
            var baz: Int

            init() { }
            init(id: Int? = nil, bar: String, baz: Int) {
                self.id = id
                self.bar = bar
                self.baz = baz
            }
        }
        struct FooMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos")
                    .field("id", .int, .identifier(auto: true))
                    .field("bar", .string, .required)
                    .field("baz", .int, .required)
                    .unique(on: "bar", "baz")
                    .create()
            }
            
            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos").delete()
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
            GalaxyMigration()
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
        final class SoftDeleteUser: Model {
            static let schema = "sd_users"

            @ID(key: "id")
            var id: Int?

            @Field(key: "name")
            var name: String

            @Timestamp(key: "deleted_at", on: .delete)
            var deletedAt: Date?

            init() { }
            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
            }
        }

        struct SDUserMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("sd_users")
                    .field("id", .int, .identifier(auto: true))
                    .field("name", .string, .required)
                    .field("deleted_at", .datetime)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("sd_users").delete()
            }
        }


        func testCounts(allCount: Int, realCount: Int) throws {
            let all = try SoftDeleteUser.query(on: self.database).all().wait()
            guard all.count == allCount else {
                throw Failure("all count should be \(allCount)")
            }
            let real = try SoftDeleteUser.query(on: self.database).withDeleted().all().wait()
            guard real.count == realCount else {
                throw Failure("real count should be \(realCount)")
            }
        }

        try runTest(#function, [
            SDUserMigration(),
        ]) {
            // save two users
            try SoftDeleteUser(name: "A").save(on: self.database).wait()
            try SoftDeleteUser(name: "B").save(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            // soft-delete a user
            let a = try SoftDeleteUser.query(on: self.database).filter(\.$name == "A").first().wait()!
            try a.delete(on: self.database).wait()
            try testCounts(allCount: 1, realCount: 2)

            // restore a soft-deleted user
            try a.restore(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            // force-delete a user
            try a.delete(force: true, on: self.database).wait()
            try testCounts(allCount: 1, realCount: 1)
        }
    }

    public func testTimestampable() throws {
        final class User: Model {
            static let schema = "users"

            @ID(key: "id")
            var id: Int?

            @Field(key: "name")
            var name: String

            @Timestamp(key: "created_at", on: .create)
            var createdAt: Date?

            @Timestamp(key: "updated_at", on: .update)
            var updatedAt: Date?

            init() { }
            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
                self.createdAt = nil
                self.updatedAt = nil
            }
        }

        struct UserMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users")
                    .field("id", .int, .identifier(auto: true))
                    .field("name", .string, .required)
                    .field("created_at", .datetime)
                    .field("updated_at", .datetime)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users").delete()
            }
        }


        try runTest(#function, [
            UserMigration(),
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

    public func testModelMiddleware() throws {
        struct TestError: Error {
            var string: String
        }
        final class User: Model {
            static let schema = "users"

            @ID(key: "id")
            var id: Int?

            @Field(key: "name")
            var name: String
            
            @Timestamp(key: "deletedAt", on: .delete)
            var deletedAt: Date?

            init() { }
            init(id: Int? = nil, name: String) {
                self.id = id
                self.name = name
            }
        }
        
        struct UserMiddleware: ModelMiddleware {
            func create(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
                model.name = "B"
                
                return next.create(model, on: db).flatMap {
                    return db.eventLoop.makeFailedFuture(TestError(string: "didCreate"))
                }
            }
            
            func update(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
                model.name = "D"
                
                return next.update(model, on: db).flatMap {
                    return db.eventLoop.makeFailedFuture(TestError(string: "didUpdate"))
                }
            }
            
            func softDelete(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
                model.name = "E"
                
                return next.softDelete(model, on: db).flatMap {
                    return db.eventLoop.makeFailedFuture(TestError(string: "didSoftDelete"))
                }
            }
            
            func restore(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
                model.name = "F"
                
                return next.restore(model , on: db).flatMap {
                    return db.eventLoop.makeFailedFuture(TestError(string: "didRestore"))
                }
            }
            
            func delete(model: User, force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
                model.name = "G"
                
                return next.delete(model, force: force, on: db).flatMap {
                    return db.eventLoop.makeFailedFuture(TestError(string: "didDelete"))
                }
            }
        }

        struct UserMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users")
                    .field("id", .int, .identifier(auto: true))
                    .field("name", .string, .required)
                    .field("deletedAt", .datetime)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users").delete()
            }
        }

        try runTest(#function, [
            UserMigration(),
        ]) {
            self.database.configuration.middleware.append(UserMiddleware())
            
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

            // soft delete
            do {
                try user.delete(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didSoftDelete")
            }
            XCTAssertEqual(user.name, "E")
            
            // restore
            do {
                try user.restore(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didRestore")
            }
            XCTAssertEqual(user.name, "F")
            
            // force delete
            do {
                try user.delete(force: true, on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didDelete")
            }
            XCTAssertEqual(user.name, "G")
        }
    }

    public func testSort() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
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
            static let schema = "users"

            @ID(key: "id")
            var id: UUID?

            @Field(key: "name")
            var name: String

            init() { }
            init(id: UUID? = nil, name: String) {
                self.id = id
                self.name = name
            }
        }

        struct UserMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users")
                    .field("id", .uuid, .identifier(auto: false))
                    .field("name", .string, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("users").delete()
            }
        }

        // seeded db
        try runTest(#function, [
            UserMigration(),
        ]) {
            try User(name: "Vapor")
                .save(on: self.database).wait()
            guard try User.query(on: self.database).count().wait() == 1 else {
                throw Failure("User did not save")
            }
        }
    }

    public func testNewModelDecode() throws {
        final class Todo: Model {
            static let schema = "todos"

            @ID(key: "id")
            var id: UUID?

            @Field(key: "title")
            var title: String

            init() { }
            init(id: UUID? = nil, title: String) {
                self.id = id
                self.title = title
            }
        }

        struct TodoMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("todos")
                    .field("id", .uuid, .identifier(auto: false))
                    .field("title", .string, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("todos").delete()
            }
        }

        // seeded db
        try runTest(#function, [
            TodoMigration(),
        ]) {
            let todo = """
            {"title": "Finish Vapor 4"}
            """
            try JSONDecoder().decode(Todo.self, from: todo.data(using: .utf8)!)
                .save(on: self.database).wait()
            guard try Todo.query(on: self.database).count().wait() == 1 else {
                throw Failure("Todo did not save")
            }
        }
    }

    public func testSiblingsAttach() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed(),
            PlanetMigration(),
            PlanetSeed(),
            TagMigration(),
            TagSeed(),
            PlanetTagMigration()
        ]) {
            let inhabited = try Tag.query(on: self.database)
                .filter(\.$name == "Inhabited")
                .first().wait()!
            let smallRocky = try Tag.query(on: self.database)
                .filter(\.$name == "Small Rocky")
                .first().wait()!
            let gasGiant = try Tag.query(on: self.database)
                .filter(\.$name == "Gas Giant")
                .first().wait()!
            let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .first().wait()!

            try earth.$tags.attach(inhabited, on: self.database).wait()
            try earth.$tags.attach(smallRocky, on: self.database).wait()

            // check tag has expected planet
            do {
                let planets = try inhabited.$planets.query(on: self.database)
                    .all().wait()
                guard planets.count == 1 else {
                    throw Failure("expected 1 planet")
                }
                guard planets[0].name == "Earth" else {
                    throw Failure("expected earth")
                }
            }

            // check unused tag has no planets
            do {
                let planets = try gasGiant.$planets.query(on: self.database)
                    .all().wait()
                guard planets.count == 0 else {
                    throw Failure("expected 0 planets")
                }
            }

            // check earth has tags
            do {
                let tags = try earth.$tags.query(on: self.database)
                    .sort(\.$name)
                    .all().wait()

                guard tags.count == 2 else {
                    throw Failure("expected 2 tags")
                }
                guard tags[0].name == "Inhabited" else {
                    throw Failure("expected inhabited tag")
                }
                guard tags[1].name == "Small Rocky" else {
                    throw Failure("expected small rocky tag")
                }
            }

            try earth.$tags.detach(smallRocky, on: self.database).wait()

            // check earth has a tag removed
            do {
                let tags = try earth.$tags.query(on: self.database)
                    .all().wait()

                guard tags.count == 1 else {
                    throw Failure("expected 2 tags")
                }
                guard tags[0].name == "Inhabited" else {
                    throw Failure("expected inhabited tag")
                }
                let planets = try smallRocky.$planets.query(on: self.database)
                    .all().wait()
                guard planets.count == 0 else {
                    throw Failure("expected 0 planets")
                }
            }
        }
    }

    public func testSiblingsEagerLoad() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed(),
            PlanetMigration(),
            PlanetSeed(),
            TagMigration(),
            TagSeed(),
            PlanetTagMigration(),
            PlanetTagSeed()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$galaxy)
                .with(\.$tags)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(planet.galaxy.name, "Milky Way")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Small Rocky", "Inhabited"])
                case "PA-99-N2":
                    XCTAssertEqual(planet.galaxy.name, "Andromeda")
                    XCTAssertEqual(planet.tags.map { $0.name }, [])
                case "Jupiter":
                    XCTAssertEqual(planet.galaxy.name, "Milky Way")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Gas Giant"])
                default: break
                }
            }
        }
    }

    public func testParentGet() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed(),
            PlanetMigration(),
            PlanetSeed(),
        ]) {
            let planets = try Planet.query(on: self.database)
                .all().wait()

            for planet in planets {
                let galaxy = try planet.$galaxy.get(on: self.database).wait()
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(galaxy.name, "Milky Way")
                case "PA-99-N2":
                    XCTAssertEqual(galaxy.name, "Andromeda")
                case "Jupiter":
                    XCTAssertEqual(galaxy.name, "Milky Way")
                default: break
                }
            }
        }
    }

    public func testParentSerialization() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed(),
            PlanetMigration(),
            PlanetSeed(),
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .all().wait()
            
            struct GalaxyKey: CodingKey, ExpressibleByStringLiteral {
                var stringValue: String
                var intValue: Int? {
                    return Int(self.stringValue)
                }
                
                init(stringLiteral value: String) {
                    self.stringValue = value
                }
                
                init?(stringValue: String) {
                    self.stringValue = stringValue
                }
                
                init?(intValue: Int) {
                    self.stringValue = intValue.description
                }
            }
            
            struct GalaxyJSON: Codable {
                var id: Int
                var name: String
                
                init(from decoder: Decoder) throws {
                    let keyed = try decoder.container(keyedBy: GalaxyKey.self)
                    self.id = try keyed.decode(Int.self, forKey: "id")
                    self.name = try keyed.decode(String.self, forKey: "name")
                    XCTAssertEqual(keyed.allKeys.count, 2)
                }
            }

            let encoded = try JSONEncoder().encode(galaxies)
            print(String(decoding: encoded, as: UTF8.self))
            
            let decoded = try JSONDecoder().decode([GalaxyJSON].self, from: encoded)
            XCTAssertEqual(galaxies.map { $0.id }, decoded.map { $0.id })
            XCTAssertEqual(galaxies.map { $0.name }, decoded.map { $0.name })
        }
    }

    public func testMultipleJoinSameTable() throws {
        // seeded db
        try runTest(#function, [
            TeamMigration(),
            MatchMigration(),
            TeamMatchSeed()
        ]) {
            // test fetching teams
            do {
                let teams = try Team.query(on: self.database)
                    .with(\.$awayMatches).with(\.$homeMatches)
                    .all().wait()
                for team in teams {
                    for homeMatch in team.homeMatches {
                        XCTAssert(homeMatch.name.hasPrefix(team.name))
                        XCTAssert(!homeMatch.name.hasSuffix(team.name))
                    }
                    for awayMatch in team.awayMatches {
                        XCTAssert(!awayMatch.name.hasPrefix(team.name))
                        XCTAssert(awayMatch.name.hasSuffix(team.name))
                    }
                }
            }

            // test fetching matches
            do {
                let matches = try Match.query(on: self.database)
                    .with(\.$awayTeam).with(\.$homeTeam)
                    .all().wait()
                for match in matches {
                    XCTAssert(match.name.hasPrefix(match.homeTeam.name))
                    XCTAssert(match.name.hasSuffix(match.awayTeam.name))
                }
            }

            struct HomeTeam: ModelAlias {
                typealias Model = Team
                static var alias: String { "home_teams" }
            }

            struct AwayTeam: ModelAlias {
                typealias Model = Team
                static var alias: String { "away_teams" }
            }

            // test manual join
            do {
                let matches = try Match.query(on: self.database)
                    .join(HomeTeam.self, on: \Match.$homeTeam == \Team.$id)
                    .join(AwayTeam.self, on: \Match.$awayTeam == \Team.$id)
                    .filter(HomeTeam.self, \Team.$name == "a")
                    .all().wait()

                for match in matches {
                    let home = try match.joined(HomeTeam.self)
                    let away = try match.joined(AwayTeam.self)
                    print(match.name)
                    print("home: \(home.name)")
                    print("away: \(away.name)")
                }
            }
        }
    }

    public func testOptionalParent() throws {
        try runTest(#function, [
            UserMigration()
        ]) {
            // seed
            do {
                let swift = User(
                    name: "Swift",
                    pet: .init(name: "Foo", type: .dog),
                    bestFriend: nil
                )
                try swift.save(on: self.database).wait()
                let vapor = User(
                    name: "Vapor",
                    pet: .init(name: "Bar", type: .cat),
                    bestFriend: swift
                )
                try vapor.save(on: self.database).wait()
            }

            // test
            let users = try User.query(on: self.database)
                .with(\.$bestFriend)
                .with(\.$friends)
                .all().wait()
            for user in users {
                switch user.name {
                case "Swift":
                    XCTAssertEqual(user.bestFriend?.name, nil)
                    XCTAssertEqual(user.friends.count, 1)
                case "Vapor":
                    XCTAssertEqual(user.bestFriend?.name, "Swift")
                    XCTAssertEqual(user.friends.count, 0)
                default:
                    XCTFail("unexpected name: \(user.name)")
                }
            }
            
            // test query with no ids
            // https://github.com/vapor/fluent-kit/issues/85
            let users2 = try User.query(on: self.database)
                .with(\.$bestFriend)
                .filter(\.$bestFriend == nil)
                .all().wait()
            XCTAssertEqual(users2.count, 1)
            XCTAssert(users2.first?.bestFriend == nil)
        }
    }
  
    public func testFieldFilter() throws {
        // seeded db
        try runTest(#function, [
            MoonMigration(),
            MoonSeed()
        ]) {
            // test filtering on columns
            let equalNumbers = try Moon.query(on: self.database).filter(\.$craters == \.$comets).all().wait()
            XCTAssertEqual(equalNumbers.count, 2)
            let moreCraters = try Moon.query(on: self.database).filter(\.$craters > \.$comets).all().wait()
            XCTAssertEqual(moreCraters.count, 3)
            let moreComets = try Moon.query(on: self.database).filter(\.$craters < \.$comets).all().wait()
            XCTAssertEqual(moreComets.count, 2)
        }
    }

    public func testJoinedFieldFilter() throws {
        // seeded db
        try runTest(#function, [
            CityMigration(),
            CitySeed(),
            SchoolMigration(),
            SchoolSeed()
        ]) {
            let smallSchools = try School.query(on: self.database)
                .join(\.$city)
                .filter(\School.$pupils < \City.$averagePupils)
                .all()
                .wait()
            XCTAssertEqual(smallSchools.count, 3)

            let largeSchools = try School.query(on: self.database)
                .join(\.$city)
                .filter(\School.$pupils > \City.$averagePupils)
                .all()
                .wait()
            XCTAssertEqual(largeSchools.count, 4)

            let averageSchools = try School.query(on: self.database)
                .join(\.$city)
                .filter(\School.$pupils == \City.$averagePupils)
                .all()
                .wait()
            XCTAssertEqual(averageSchools.count, 1)
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
        for migration in migrations.reversed() {
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
