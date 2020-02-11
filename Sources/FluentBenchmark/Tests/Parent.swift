extension FluentBenchmarker {
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
}
