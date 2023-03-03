import SQLKit
import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testJoin() throws {
        try self.testJoin_basic()
        try self.testJoin_sameTable()
        try self.testJoin_fieldFilter()
        try self.testJoin_fieldOrdering()
        try self.testJoin_aliasNesting()
        try self.testJoin_partialSelect()
        try self.testJoin_complexCondition()
    }

    private func testJoin_basic() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .join(Star.self, on: \Planet.$star.$id == \Star.$id)
                .all().wait()

            for planet in planets {
                let star = try planet.joined(Star.self)
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(star.name, "Sun")
                case "Proxima Centauri b":
                    XCTAssertEqual(star.name, "Alpha Centauri")
                default: break
                }
            }

            let galaxies = try Galaxy.query(on: self.database)
                .join(Star.self, on: \Galaxy.$id == \Star.$galaxy.$id)
                .all()
                .wait()

            for galaxy in galaxies {
                let star = try galaxy.joined(Star.self)
                switch star.name {
                case "Sun", "Alpha Centauri":
                    XCTAssertEqual(galaxy.name, "Milky Way")
                case "Alpheratz":
                    XCTAssertEqual(galaxy.name, "Andromeda")
                default: break
                }
            }
        }
    }

    private func testJoin_sameTable() throws {
        try self.runTest(#function, [
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
                    .with(\.$awayTeam)
                    .with(\.$homeTeam)
                    .all().wait()
                for match in matches {
                    XCTAssert(match.name.hasPrefix(match.homeTeam.name))
                    XCTAssert(match.name.hasSuffix(match.awayTeam.name))
                }
            }

            final class HomeTeam: ModelAlias {
                static let name = "home_teams"
                let model = Team()
            }

            final class AwayTeam: ModelAlias {
                static let name = "away_teams"
                let model = Team()
            }

            // test manual join
            do {
                let matches = try Match.query(on: self.database)
                    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
                    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
                    .filter(HomeTeam.self, \.$name == "a")
                    .sort(AwayTeam.self, \.$name)
                    .all().wait()

                for match in matches {
                    let home = try match.joined(HomeTeam.self)
                    self.database.logger.debug("home: \(home)")
                    let away = try match.joined(AwayTeam.self)
                    self.database.logger.debug("away: \(away)")
                }
            }
        }
    }

    private func testJoin_fieldFilter() throws {
        // seeded db
        try runTest(#function, [
            CityMigration(),
            CitySeed(),
            SchoolMigration(),
            SchoolSeed()
        ]) {
            let smallSchools = try School.query(on: self.database)
                .join(City.self, on: \School.$city.$id == \City.$id)
                .filter(\School.$pupils < \City.$averagePupils)
                .all()
                .wait()
            XCTAssertEqual(smallSchools.count, 3)

            let largeSchools = try School.query(on: self.database)
                .join(City.self, on: \School.$city.$id == \City.$id)
                .filter(\School.$pupils > \City.$averagePupils)
                .all()
                .wait()
            XCTAssertEqual(largeSchools.count, 4)

            let averageSchools = try School.query(on: self.database)
                .join(City.self, on: \School.$city.$id == \City.$id)
                .filter(\School.$pupils == \City.$averagePupils)
                .all()
                .wait()
            XCTAssertEqual(averageSchools.count, 1)
        }
    }


    private func testJoin_fieldOrdering() throws {
        _ = School.query(on: self.database)
            .join(City.self, on: \School.$city.$id == \City.$id)
        _ = School.query(on: self.database)
            .join(City.self, on: \City.$id == \School.$city.$id)
    }

    private func testJoin_aliasNesting() throws {
        final class ChatParticipant: Model {
            static let schema = "chat_participants"

            @ID(key: .id)
            var id: UUID?

            @Parent(key: "user_id")
            var user: User
        }

        final class User: Model {
            static let schema = "users"

            @ID(key: .id)
            var id: UUID?
        }

        final class MeAsAParticipant: ModelAlias {
            static let name: String = "me_as_a_participant"
            let model = ChatParticipant()
        }
        final class OtherParticipant: ModelAlias {
            static let name: String = "other_participant"
            var model = ChatParticipant()
        }

        _ = User.query(on: self.database)
            .join(OtherParticipant.self, on: \User.$id == \OtherParticipant.$user.$id)
    }

    private func testJoin_partialSelect() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .field(\.$name)
                .join(Star.self, on: \Planet.$star.$id == \Star.$id)
                .filter(Star.self, \.$name ~~ ["Sun", "Alpha Centauri"])
                .field(Star.self, \.$name)
                .all().wait()

            for planet in planets {
                XCTAssertNil(planet.$id.value)
                let star = try planet.joined(Star.self)
                XCTAssertNil(star.$id.value)
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(star.name, "Sun")
                case "Proxima Centauri b":
                    XCTAssertEqual(star.name, "Alpha Centauri")
                default: break
                }

            }
        }
    }
    
    private func testJoin_complexCondition() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            guard self.database is SQLDatabase else { return }
            
            let planets = try Planet.query(on: self.database)
                .join(Star.self, on: \Planet.$star.$id == \Star.$id && \Star.$name != \Planet.$name)
                .all().wait()
            
            XCTAssertFalse(planets.isEmpty)
        }
    }
}

private final class Team: Model {
    static let schema = "teams"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Children(for: \.$homeTeam)
    var homeMatches: [Match]

    @Children(for: \.$awayTeam)
    var awayMatches: [Match]

    init() { }

    init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

private struct TeamMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("teams")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("teams").delete()
    }
}

private final class Match: Model {
    static let schema = "matches"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Parent(key: "home_team_id")
    var homeTeam: Team

    @Parent(key: "away_team_id")
    var awayTeam: Team

    init() { }

    init(id: IDValue? = nil, name: String, homeTeam: Team, awayTeam: Team) {
        self.id = id
        self.name = name
        self.$homeTeam.id = homeTeam.id!
        self.$awayTeam.id = awayTeam.id!
    }
}

struct MatchMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("matches")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("away_team_id", .uuid, .required)
            .field("home_team_id", .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("matches").delete()
    }
}

private struct TeamMatchSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let a = Team(name: "a")
        let b = Team(name: "b")
        let c = Team(name: "c")
        return a.create(on: database).and(b.create(on: database)).and(c.create(on: database)).flatMap { _ -> EventLoopFuture<Void> in
            return .andAllSucceed([
                Match(name: "a vs. b", homeTeam: a, awayTeam: b).save(on: database),
                Match(name: "a vs. c", homeTeam: a, awayTeam: c).save(on: database),
                Match(name: "b vs. c", homeTeam: b, awayTeam: c).save(on: database),
                Match(name: "b vs. a", homeTeam: b, awayTeam: a).save(on: database),
                Match(name: "c vs. b", homeTeam: c, awayTeam: b).save(on: database),
                Match(name: "c vs. a", homeTeam: c, awayTeam: a).save(on: database),
            ], on: database.eventLoop)
        }

    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        Match.query(on: database).delete().flatMap {
            Team.query(on: database).delete()
        }

    }
}


private final class School: Model {
    static let schema = "schools"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "pupils")
    var pupils: Int

    @Parent(key: "city_id")
    var city: City

    init() { }

    init(id: IDValue? = nil, name: String, pupils: Int, cityID: City.IDValue) {
        self.id = id
        self.name = name
        self.pupils = pupils
        self.$city.id = cityID
    }
}

private struct SchoolMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("schools")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("pupils", .int, .required)
            .field("city_id", .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("schools").delete()
    }
}

private struct SchoolSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let amsterdam = self.add(
            [
                (name: "schoolA1", pupils: 500),
                (name: "schoolA2", pupils: 250),
                (name: "schoolA3", pupils: 400),
                (name: "schoolA4", pupils: 50)
            ],
            to: "Amsterdam",
            on: database
        )
        let newYork = self.add(
            [
                (name: "schoolB1", pupils: 500),
                (name: "schoolB2", pupils: 500),
                (name: "schoolB3", pupils: 400),
                (name: "schoolB4", pupils: 200)
            ],
            to: "New York",
            on: database
        )
        return .andAllSucceed([amsterdam, newYork], on: database.eventLoop)
    }

    private func add(_ schools: [(name: String, pupils: Int)], to city: String, on database: Database) -> EventLoopFuture<Void> {
        return City.query(on: database)
            .filter(\.$name == city)
            .first()
            .flatMap { city -> EventLoopFuture<Void> in
                guard let city = city else {
                    return database.eventLoop.makeSucceededFuture(())
                }
                let saves = schools.map { school -> EventLoopFuture<Void> in
                    return School(name: school.name, pupils: school.pupils, cityID: city.id!)
                        .save(on: database)
                }
                return .andAllSucceed(saves, on: database.eventLoop)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}

private final class City: Model {
    static let schema = "cities"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "avg_pupils")
    var averagePupils: Int

    @Children(for: \.$city)
    var schools: [School]

    init() { }

    init(id: IDValue? = nil, name: String, averagePupils: Int) {
        self.id = id
        self.name = name
        self.averagePupils = averagePupils
    }
}

private struct CityMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("cities")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("avg_pupils", .int, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("cities").delete()
    }
}

private struct CitySeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let saves = [
            City(name: "Amsterdam", averagePupils: 300),
            City(name: "New York", averagePupils: 400)
        ].map { city -> EventLoopFuture<Void> in
            return city.save(on: database)
        }
        return .andAllSucceed(saves, on: database.eventLoop)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
