extension FluentBenchmarker {
    public func testEagerLoading() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
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

            let planets = try Planet.query(on: self.database)
                ._with(\.$galaxy)
                ._with(\.$galaxy, \.$planets)
                .all().wait()
            let json = JSONEncoder()
            json.outputFormatting = .prettyPrinted
            try print(String(decoding: json.encode(planets), as: UTF8.self))
            print(planets)
        }
    }
}
