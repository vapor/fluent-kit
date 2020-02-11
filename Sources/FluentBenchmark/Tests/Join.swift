extension FluentBenchmarker {
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

            let galaxies = try Galaxy.query(on: self.database)
                .join(Planet.self, on: \Galaxy.$id == \Planet.$galaxy.$id)
                .all()
                .wait()

            for galaxy in galaxies {
                let planet = try galaxy.joined(Planet.self)
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
}
