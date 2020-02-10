extension FluentBenchmarker {
    public func testEagerLoading() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            MoonMigration(),
            GalaxySeed(),
            PlanetSeed(),
            MoonSeed()
        ]) {
//            let galaxies = try Galaxy.query(on: self.database)
//                ._with(\.$planets)
//                .all().wait()
//
//            print(galaxies)
//
//            let planets = try Planet.query(on: self.database)
//                ._with(\.$galaxy)
//                .all().wait()
//
//            print(planets)

            let galaxies = try Galaxy.query(on: self.database)
                ._with(\.$planets)
                ._with(\.$planets) {
                    $0._with(\.$moons)
                }
                .all().wait()
            let json = JSONEncoder()
            json.outputFormatting = .prettyPrinted
            try print(String(decoding: json.encode(galaxies), as: UTF8.self))
            print(galaxies)
        }
    }
}
