import XCTest
import Dispatch
import FluentKit
import Foundation
import NIOCore
import SQLKit

extension FluentBenchmarker {
    internal func testPerformance_siblings() throws {
        // we know database will outlive this test
        // so doing this is fine.
        // otherwise threading is a PITA
        let conn = try self.database.withConnection { 
            $0.eventLoop.makeSucceededFuture($0)
        }.wait()

        // this test makes a ton of queries so doing it
        // on a single connection helps combat pool timeouts
        try self.runTest("testPerformance_siblings", [
            PersonMigration(),
            ExpeditionMigration(),
            ExpeditionOfficerMigration(),
            ExpeditionScientistMigration(),
            ExpeditionDoctorMigration(),
            PersonSeed(),
            ExpeditionSeed(),
            ExpeditionPeopleSeed(),
        ], on: conn) { conn in
            let start = Date()
            let expeditions = try Expedition.query(on: conn)
                .with(\.$officers)
                .with(\.$scientists)
                .with(\.$doctors)
                .all().wait()
            let time = Date().timeIntervalSince(start)
            // Circa Swift 5.2:
            // Run took 24.121525049209595 seconds.
            // Run took 0.33231091499328613 seconds.
            // Circa Swift 5.8:
            // Run took 1.6426270008087158 seconds.
            // Run took 0.40939199924468994 seconds.
            conn.logger.info("Run took \(time) seconds.")
            XCTAssertEqual(expeditions.count, 300)
            if let sqlConn = conn as? any SQLDatabase {
                struct DTO1: Codable { let id: UUID; let name: String, area: String, objective: String }
                struct DTO2: Codable { let id: UUID, expedition_id: UUID, person_id: UUID }
                let start = Date()
                let expeditions = try sqlConn.select().columns("id", "name", "area", "objective").from(Expedition.schema).all(decoding: DTO1.self).wait()
                let officers = try sqlConn.select().columns("id", "expedition_id", "person_id").from(ExpeditionOfficer.schema).where(SQLIdentifier("expedition_id"), .in, expeditions.map(\.id)).all(decoding: DTO2.self).wait()
                let scientists = try sqlConn.select().columns("id", "expedition_id", "person_id").from(ExpeditionScientist.schema).where(SQLIdentifier("expedition_id"), .in, expeditions.map(\.id)).all(decoding: DTO2.self).wait()
                let doctors = try sqlConn.select().columns("id", "expedition_id", "person_id").from(ExpeditionDoctor.schema).where(SQLIdentifier("expedition_id"), .in, expeditions.map(\.id)).all(decoding: DTO2.self).wait()
                let time = Date().timeIntervalSince(start)
                // Run (SQLKit mode) took 0.6164050102233887 seconds.
                // Run (SQLKit mode) took 0.050302982330322266 seconds.
                conn.logger.info("Run (SQLKit mode) took \(time) seconds.")
                XCTAssertEqual(expeditions.count, 300)
                XCTAssertEqual(officers.count, 600)
                XCTAssertEqual(scientists.count, 1500)
                XCTAssertEqual(doctors.count, 900)
            }
        }
    }
}

private struct PersonSeed: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        if let sqlDatabase = database as? any SQLDatabase {
            struct DTO: Codable { let id: UUID; let first_name: String, last_name: String }
            return try! sqlDatabase.insert(into: Person.schema)
                .models((1...600).map { DTO(id: UUID(), first_name: "Foo #\($0)", last_name: "Bar") })
                .run()
        } else {
            return .andAllSucceed((1...600).map { i in
                Person(firstName: "Foo #\(i)", lastName: "Bar")
                    .create(on: database)
            }, on: database.eventLoop)
        }
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        Person.query(on: database).delete()
    }
}

private struct ExpeditionSeed: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        if let sqlDatabase = database as? any SQLDatabase {
            struct DTO: Codable { let id: UUID; let name: String, area: String, objective: String }
            return try! sqlDatabase.insert(into: Expedition.schema)
                .models((1...300).map { DTO(id: UUID(), name: "Baz #\($0)", area: "Qux", objective: "Quuz") })
                .run()
        } else {
            return .andAllSucceed((1...300).map { i in
                Expedition(name: "Baz #\(i)", area: "Qux", objective: "Quuz")
                    .create(on: database)
            }, on: database.eventLoop)
        }
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        Expedition.query(on: database).delete()
    }
}

private struct ExpeditionPeopleSeed: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        if let sqlDatabase = database as? any SQLDatabase {
            return
                sqlDatabase.select().column("id").from(Expedition.schema).all().flatMapEachThrowing { try $0.decode(column: "id", as: UUID.self) }
                .and(sqlDatabase.select().column("id").from(Person.schema).all().flatMapEachThrowing { try $0.decode(column: "id", as: UUID.self) })
                .flatMap { expeditions, people in
                    struct DTO: Codable { let id: UUID, expedition_id: UUID, person_id: UUID }
                    var officers: [DTO] = [], scientists: [DTO] = [], doctors: [DTO] = []
                    
                    for expedition in expeditions {
                        officers.append(contentsOf: people.pickRandomly(2).map { DTO(id: UUID(), expedition_id: expedition, person_id: $0) })
                        scientists.append(contentsOf: people.pickRandomly(5).map { DTO(id: UUID(), expedition_id: expedition, person_id: $0) })
                        doctors.append(contentsOf: people.pickRandomly(3).map { DTO(id: UUID(), expedition_id: expedition, person_id: $0) })
                    }
                    return .andAllSucceed([
                        try! sqlDatabase.insert(into: ExpeditionOfficer.schema).models(officers).run(),
                        try! sqlDatabase.insert(into: ExpeditionScientist.schema).models(scientists).run(),
                        try! sqlDatabase.insert(into: ExpeditionDoctor.schema).models(doctors).run(),
                    ], on: sqlDatabase.eventLoop)
                }
        } else {
            return Expedition.query(on: database).all()
                .and(Person.query(on: database).all())
                .flatMap
            { (expeditions, people) in
                .andAllSucceed(expeditions.map { expedition in
                    expedition.$officers.attach(people.pickRandomly(2), on: database)
                        .and(expedition.$scientists.attach(people.pickRandomly(5), on: database))
                        .and(expedition.$doctors.attach(people.pickRandomly(3), on: database))
                        .map { _ in }
                }, on: database.eventLoop)
            }
        }
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            ExpeditionOfficer.query(on: database).delete(),
            ExpeditionScientist.query(on: database).delete(),
            ExpeditionDoctor.query(on: database).delete(),
        ], on: database.eventLoop)
    }
}

private final class Person: Model {
    static let schema = "people"

    @ID
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Siblings(through: ExpeditionOfficer.self, from: \.$person, to: \.$expedition)
    var expeditionsAsOfficer: [Expedition]

    @Siblings(through: ExpeditionScientist.self, from: \.$person, to: \.$expedition)
    var expeditionsAsScientist: [Expedition]

    @Siblings(through: ExpeditionDoctor.self, from: \.$person, to: \.$expedition)
    var expeditionsAsDoctor: [Expedition]

    init() { }

    init(id: UUID? = nil, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}

private struct PersonMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("people")
            .field("id", .uuid, .identifier(auto: false))
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("people").delete()
    }
}

private final class Expedition: Model {
    static let schema = "expeditions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "area")
    var area: String?

    @Field(key: "objective")
    var objective: String

    @Siblings(through: ExpeditionOfficer.self, from: \.$expedition, to: \.$person)
    var officers: [Person]

    @Siblings(through: ExpeditionScientist.self, from: \.$expedition, to: \.$person)
    var scientists: [Person]

    @Siblings(through: ExpeditionDoctor.self, from: \.$expedition, to: \.$person)
    var doctors: [Person]

    init() { }

    init(
        id: UUID? = nil,
        name: String,
        area: String?,
        objective: String
    ) {
        self.id = id
        self.name = name
        self.area = area
        self.objective = objective
    }
}

private struct ExpeditionMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expeditions")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("area", .string)
            .field("objective", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expeditions").delete()
    }
}

private final class ExpeditionOfficer: Model {
    static let schema = "expedition+officer"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "expedition_id")
    var expedition: Expedition

    @Parent(key: "person_id")
    var person: Person

    init() { }
}

private struct ExpeditionOfficerMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expedition+officer")
            .field("id", .uuid, .identifier(auto: false))
            .field("expedition_id", .uuid, .required, .references("expeditions", "id"))
            .field("person_id", .uuid, .required, .references("people", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expedition+officer").delete()
    }
}

private final class ExpeditionScientist: Model {
    static let schema = "expedition+scientist"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "expedition_id")
    var expedition: Expedition

    @Parent(key: "person_id")
    var person: Person

    init() { }
}

private struct ExpeditionScientistMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expedition+scientist")
            .field("id", .uuid, .identifier(auto: false))
            .field("expedition_id", .uuid, .required, .references("expeditions", "id"))
            .field("person_id", .uuid, .required, .references("people", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expedition+scientist").delete()
    }
}


private final class ExpeditionDoctor: Model {
    static let schema = "expedition+doctor"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "expedition_id")
    var expedition: Expedition

    @Parent(key: "person_id")
    var person: Person

    init() { }

    init(expeditionID: UUID, personID: UUID) {
        self.$expedition.id = expeditionID
        self.$person.id = personID
    }
}

private struct ExpeditionDoctorMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expedition+doctor")
            .field("id", .uuid, .identifier(auto: false))
            .field("expedition_id", .uuid, .required, .references("expeditions", "id"))
            .field("person_id", .uuid, .required, .references("people", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("expedition+doctor").delete()
    }
}

extension Array {
    func pickRandomly(_ n: Int) -> [Element] {
        var random: [Element] = []
        for _ in 0..<n {
            random.append(self.randomElement()!)
        }
        return random
    }
}
