extension FluentBenchmarker {
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

}
