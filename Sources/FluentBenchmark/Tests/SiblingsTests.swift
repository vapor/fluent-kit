import XCTest
import FluentKit

extension FluentBenchmarker {
    public func testSiblings() throws {
        try self.testSiblings_attach()
        try self.testSiblings_detachArray()
        try self.testSiblings_pivotLoading()
        try self.testSiblings_detachAll()
    }

    private func testSiblings_attach() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let inhabited = try Tag.query(on: self.database)
                .filter(\.$name == "Inhabited")
                .first().wait()!
            let smallRocky = try Tag.query(on: self.database)
                .filter(\.$name == "Small Rocky")
                .first().wait()!
            let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .first().wait()!

            // check tag has expected planet
            do {
                let planets = try inhabited.$planets.query(on: self.database)
                    .all().wait()
                XCTAssertEqual(planets.count, 1)
                XCTAssertEqual(planets.first?.name, "Earth")
            }

            // check earth has tags
            do {
                let tags = try earth.$tags.query(on: self.database)
                    .sort(\.$name)
                    .all().wait()

                XCTAssertEqual(tags.count, 2)
                XCTAssertEqual(tags.map(\.name).sorted(), ["Inhabited", "Small Rocky"])
            }

            try earth.$tags.detach(smallRocky, on: self.database).wait()

            // check earth has a tag removed
            do {
                let tags = try earth.$tags.query(on: self.database)
                    .all().wait()

                XCTAssertEqual(tags.count, 1)
                XCTAssertEqual(tags.first?.name, "Inhabited")
            }

            try earth.$tags.attach(smallRocky, on: self.database).wait()

            // check earth has a tag added
            do {
                let tags = try earth.$tags.query(on: self.database)
                    .all().wait()

                XCTAssertEqual(tags.count, 2)
                XCTAssertEqual(tags.map(\.name).sorted(), ["Inhabited", "Small Rocky"])
            }
            
            try earth.$tags.detachAll(on: self.database).wait()
            
            // check pivot provided to the edit closure has the "to" model when attaching
            try earth.$tags.attach([inhabited, smallRocky], on: self.database) { pivot in
                guard pivot.$tag.value != nil else {
                    return XCTFail("planet tag pivot should have tag available during editing")
                }
                pivot.comments = "Tagged with name \(pivot.tag.name)"
            }.wait()
            
            do {
                let pivots = try earth.$tags.$pivots.get(reload: true, on: self.database).wait()
                
                XCTAssertEqual(pivots.count, 2)
                XCTAssertEqual(pivots.compactMap(\.comments).sorted(), ["Tagged with name Inhabited", "Tagged with name Small Rocky"])
            }
        }
    }

    private func testSiblings_detachArray() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let inhabited = try Tag.query(on: self.database)
                .filter(\.$name == "Inhabited")
                .first().wait()!
            let smallRocky = try Tag.query(on: self.database)
                .filter(\.$name == "Small Rocky")
                .first().wait()!
            let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .first().wait()!

            // verify tag count
            try XCTAssertEqual(earth.$tags.query(on: self.database).count().wait(), 2)

            try earth.$tags.detach([smallRocky, inhabited], on: self.database).wait()

            // check earth has tags removed
            do {
                let tags = try earth.$tags.query(on: self.database)
                    .all().wait()
                XCTAssertEqual(tags.count, 0)
            }
        }
    }
    
    private func testSiblings_pivotLoading() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth").with(\.$tags).with(\.$tags.$pivots)
                .first().wait()!
            
            // verify tag count
            XCTAssertEqual(earth.$tags.pivots.count, 2)
        }
    }
    
    private func testSiblings_detachAll() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .first().wait()!
            
            // verify tag count
            try XCTAssertEqual(earth.$tags.query(on: self.database).count().wait(), 2)
            
            try earth.$tags.detachAll(on: self.database).wait()
            
            // check earth has tags removed
            do {
                let tags = try earth.$tags.query(on: self.database)
                    .all().wait()
                XCTAssertEqual(tags.count, 0)
            }
        }
    }
}
