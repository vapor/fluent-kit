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
            let galaxies = try Galaxy.query(on: self.database)
                ._with(\.$stars) {
                    $0._with(\.$planets) {
                        $0._with(\.$moons)
                        $0._with(\.$tags)
                    }
                }
                .all().wait()
            let json = JSONEncoder()
            json.outputFormatting = .prettyPrinted
            try print(String(decoding: json.encode(galaxies), as: UTF8.self))
            print(galaxies)
        }
    }
}
