import XCTest
extension FluentBenchmarker {
    public func testCompositeID() throws {
        try self.testCompositeID_create()
        try self.testCompositeID_lookup()
        try self.testCompositeID_update()
        try self.testCompositeID_asPivot()
    }
    
    private func testCompositeID_create() throws {
        try self.runTest(#function, [
            CompositeIDModelMigration(),
        ]) {
            let newModel = CompositeIDModel(name: "A", dimensions: 1, additionalInfo: nil)
            try newModel.create(on: self.database).wait()
            
            let count = try CompositeIDModel.query(on: self.database).count().wait()
            XCTAssertEqual(count, 1)
            
            let anotherNewModel = CompositeIDModel(name: "A", dimensions: 1, additionalInfo: nil)
            XCTAssertThrowsError(try anotherNewModel.create(on: self.database).wait())
            
            let differentNewModel = CompositeIDModel(name: "B", dimensions: 1, additionalInfo: nil)
            try differentNewModel.create(on: self.database).wait()
            
            let anotherDifferentNewModel = CompositeIDModel(name: "A", dimensions: 2, additionalInfo: nil)
            try anotherDifferentNewModel.create(on: self.database).wait()

            let countAgain = try CompositeIDModel.query(on: self.database).count(\.$id.$name).wait()
            XCTAssertEqual(countAgain, 3)
        }
    }
    
    private func testCompositeID_lookup() throws {
        try self.runTest(#function, [
            CompositeIDModelMigration(),
            CompositeIDModelSeed(),
        ]) {
            let found = try CompositeIDModel.find(.init(name: "A", dimensions: 1), on: self.database).wait()
            XCTAssertNotNil(found)
            
            let foundByPartial = try CompositeIDModel.query(on: self.database).filter(\.$id.$name == "B").all().wait()
            XCTAssertEqual(foundByPartial.count, 1)
            XCTAssertEqual(foundByPartial.first?.id?.dimensions, 1)
            
            let foundByOtherPartial = try CompositeIDModel.query(on: self.database).filter(\.$id.$dimensions == 2).all().wait()
            XCTAssertEqual(foundByOtherPartial.count, 1)
            XCTAssertEqual(foundByOtherPartial.first?.id?.name, "A")
            
        }
    }
    
    private func testCompositeID_update() throws {
        try self.runTest(#function, [
            CompositeIDModelMigration(),
            CompositeIDModelSeed(),
        ]) {
            let existing = try XCTUnwrap(CompositeIDModel.find(.init(name: "A", dimensions: 1), on: self.database).wait())
            
            existing.additionalInfo = "additional"
            try existing.update(on: self.database).wait()
            
            XCTAssertEqual(try CompositeIDModel.query(on: self.database).filter(\.$additionalInfo == "additional").count(\.$id.$name).wait(), 1)
            
            try CompositeIDModel.query(on: self.database).filter(\.$id.$name == "A").filter(\.$id.$dimensions == 1).set(\.$id.$dimensions, to: 3).update().wait()
            XCTAssertNotNil(try CompositeIDModel.find(.init(name: "A", dimensions: 3), on: self.database).wait())
        }
    }
    
    private func testCompositeID_asPivot() throws {
        try self.runTest(#function, [
            GalaxyMigration(),
            JurisdictionMigration(),
            GalacticJurisdictionMigration(),
            GalaxySeed(),
            JurisdictionSeed(),
            GalacticJurisdictionSeed(),
        ]) {
            let milkyWayGalaxy = try XCTUnwrap(Galaxy.query(on: self.database).filter(\.$name == "Milky Way").first().wait())
            let andromedaGalaxy = try XCTUnwrap(Galaxy.query(on: self.database).filter(\.$name == "Andromeda").first().wait())
            let oldJurisdiction = try XCTUnwrap(Jurisdiction.query(on: self.database).filter(\.$title == "Old").first().wait())
            let noneJurisdiction = try XCTUnwrap(Jurisdiction.query(on: self.database).filter(\.$title == "None").first().wait())
            
            try milkyWayGalaxy.$jurisdictions.attach(oldJurisdiction, method: .always, on: self.database, { $0.$id.$rank.value = 1 }).wait()
            try noneJurisdiction.$galaxies.attach(andromedaGalaxy, method: .always, on: self.database, { $0.$id.$rank.value = 0 }).wait()
            try noneJurisdiction.$galaxies.attach(milkyWayGalaxy, method: .always, on: self.database, { $0.$id.$rank.value = 2 }).wait()
            
            let pivots = try GalacticJurisdiction.query(on: self.database).all().wait()
            
            XCTAssertEqual(pivots.count, 3)
            XCTAssertTrue(pivots.contains(where: { $0.id!.$galaxy.id == milkyWayGalaxy.id! && $0.id!.$jurisdiction.id == oldJurisdiction.id! && $0.id!.rank == 1 }))
            XCTAssertTrue(pivots.contains(where: { $0.id!.$galaxy.id == milkyWayGalaxy.id! && $0.id!.$jurisdiction.id == noneJurisdiction.id! && $0.id!.rank == 2 }))
            XCTAssertTrue(pivots.contains(where: { $0.id!.$galaxy.id == andromedaGalaxy.id! && $0.id!.$jurisdiction.id == noneJurisdiction.id! && $0.id!.rank == 0 }))
        }
    }
}

public final class CompositeIDModel: Model {
    public static let schema = "composite_id_models"
    
    public final class IDValue: Fields, Hashable {
        @Field(key: "name")
        public var name: String
        
        @Field(key: "dimensions")
        public var dimensions: Int
        
        public init() {}
        
        public init(name: String, dimensions: Int) {
            self.name = name
            self.dimensions = dimensions
        }
        
        public static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.name == rhs.name && lhs.dimensions == rhs.dimensions
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.name)
            hasher.combine(self.dimensions)
        }
    }
    
    @CompositeID()
    public var id: IDValue?
    
    @OptionalField(key: "additional_info")
    public var additionalInfo: String?
    
    public init() {}
    
    public init(id: IDValue, additionalInfo: String? = nil) {
        self.id = id
        self.additionalInfo = additionalInfo
    }
    
    public convenience init(name: String, dimensions: Int, additionalInfo: String? = nil) {
        self.init(id: .init(name: name, dimensions: dimensions), additionalInfo: additionalInfo)
    }
}

public struct CompositeIDModelMigration: Migration {
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositeIDModel.schema)
            .field("name", .string, .required)
            .field("dimensions", .int, .required)
            .field("additional_info", .string)
            .compositeIdentifier(over: "name", "dimensions")
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CompositeIDModel.schema)
            .delete()
    }
}

public struct CompositeIDModelSeed: Migration {
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        [
            CompositeIDModel(name: "A", dimensions: 1, additionalInfo: nil),
            CompositeIDModel(name: "A", dimensions: 2, additionalInfo: nil),
            CompositeIDModel(name: "B", dimensions: 1, additionalInfo: nil),
        ].map { $0.create(on: database) }.flatten(on: database.eventLoop)
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        CompositeIDModel.query(on: database)
            .group(.or) { $0
                .group(.and) { $0.filter(\.$id.$name == "A").filter(\.$id.$dimensions == 1) }
                .group(.and) { $0.filter(\.$id.$name == "A").filter(\.$id.$dimensions == 2) }
                .group(.and) { $0.filter(\.$id.$name == "B").filter(\.$id.$dimensions == 1) }
            }
            .delete()
    }
}

