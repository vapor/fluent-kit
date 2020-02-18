import XCTest

extension FluentBenchmarker {
    public func testSiblingsPerformance() throws {
        try self.runTest(#function, [
            PersonMigration(),
            ExpeditionMigration(),
            ExpeditionOfficerMigration(),
            ExpeditionScientistMigration(),
            ExpeditionDoctorMigration(),
            PersonSeed(),
            ExpeditionSeed(),
            ExpeditionPeopleSeed(),
        ]) {
            let start = Date()
            let expeditions = try Expedition.query(on: self.database)
                .with(\.$officers)
                .with(\.$scientists)
                .with(\.$doctors)
                .all().wait()
            let time = Date().timeIntervalSince(start)
            // Run took 24.121525049209595 seconds.
            // Run took 0.33231091499328613 seconds.
            print("Run took \(time) seconds.")
            XCTAssertEqual(expeditions.count, 300)
        }
    }
}

private struct PersonSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed((1...600).map { i in
            Person(firstName: "Foo #\(i)", lastName: "Bar")
                .create(on: database)
        }, on: database.eventLoop)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        Person.query(on: database).delete()
    }
}

private struct ExpeditionSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed((1...300).map { i in
            Expedition(name: "Baz #\(i)", area: "Qux", objective: "Quuz")
                .create(on: database)
        }, on: database.eventLoop)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        Expedition.query(on: database).delete()
    }
}

private struct ExpeditionPeopleSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        Expedition.query(on: database).all()
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

    func revert(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            ExpeditionOfficer.query(on: database).delete(),
            ExpeditionScientist.query(on: database).delete(),
            ExpeditionDoctor.query(on: database).delete(),
        ], on: database.eventLoop)
    }
}

private final class Person: Model {
    static let schema = "people"

    @ID(key: "id", generatedBy: .random)
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

    @ID(key: "id", generatedBy: .random)
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
        database.schema(Expedition.schema)
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("area", .string)
            .field("objective", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Expedition.schema).delete()
    }
}

private final class ExpeditionOfficer: Model {
    static let schema = "expedition+officer"

    @ID(key: "id")
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

    @ID(key: "id")
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

    @ID(key: "id")
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
