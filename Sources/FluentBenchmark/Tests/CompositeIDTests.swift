import FluentKit
import Foundation
import NIOCore
import XCTest
import SQLKit

extension FluentBenchmarker {
    public func testCompositeID() throws {
        try self.testCompositeID_create()
        try self.testCompositeID_lookup()
        try self.testCompositeID_update()
        try self.testCompositeID_asPivot()
        try self.testCompositeID_eagerLoaders()
        try self.testCompositeID_arrayCreateAndDelete()
        try self.testCompositeID_count()
        
        // Embed this here instead of having to update all the Fluent drivers
        if self.database is SQLDatabase {
            try self.testCompositeRelations()
        }
    }
    
    private func testCompositeID_create() throws {
        try self.runTest(#function, [
            CompositeIDModelMigration(),
        ]) {
            let newModel = CompositeIDModel(name: "A", dimensions: 1, additionalInfo: nil)
            try newModel.create(on: self.database).wait()
            
            let count = try CompositeIDModel.query(on: self.database).count(\.$id.$name).wait()
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
    
    private func testCompositeID_eagerLoaders() throws {
        try self.runTest(#function, [
            GalaxyMigration(),
            StarMigration(),
            JurisdictionMigration(),
            GalacticJurisdictionMigration(),
            GalaxySeed(),
            StarSeed(),
            JurisdictionSeed(),
            GalacticJurisdictionSeed(),
        ]) {
            let milkyWayGalaxy = try XCTUnwrap(Galaxy.query(on: self.database).filter(\.$name == "Milky Way").with(\.$jurisdictions).first().wait())
            XCTAssertEqual(milkyWayGalaxy.jurisdictions.count, 2)
            
            let militaryJurisdiction = try XCTUnwrap(Jurisdiction.query(on: self.database).filter(\.$title == "Military").with(\.$galaxies).with(\.$galaxies.$pivots).first().wait())
            XCTAssertEqual(militaryJurisdiction.galaxies.count, 2)
            XCTAssertEqual(militaryJurisdiction.$galaxies.pivots.count, 2)
            
            let corporateMilkyWayPivot = try XCTUnwrap(GalacticJurisdiction.query(on: self.database)
                .join(parent: \.$id.$galaxy).filter(Galaxy.self, \.$name == "Milky Way")
                .join(parent: \.$id.$jurisdiction).filter(Jurisdiction.self, \.$title == "Corporate")
                .with(\.$id.$galaxy) { $0.with(\.$stars) }.with(\.$id.$jurisdiction)
                .first().wait())
            XCTAssertNotNil(corporateMilkyWayPivot.$id.$galaxy.value)
            XCTAssertNotNil(corporateMilkyWayPivot.$id.$jurisdiction.value)
            XCTAssertEqual(corporateMilkyWayPivot.id!.galaxy.stars.count, 2)
        }
    }
    
    private func testCompositeID_arrayCreateAndDelete() throws {
        try self.runTest(#function, [
            GalaxyMigration(),
            JurisdictionMigration(),
            GalacticJurisdictionMigration(),
            GalaxySeed(),
            JurisdictionSeed(),
        ]) {
            let milkyWayGalaxy = try XCTUnwrap(Galaxy.query(on: self.database).filter(\.$name == "Milky Way").first().wait())
            let allJurisdictions = try Jurisdiction.query(on: self.database).all().wait()
            
            assert(!allJurisdictions.isEmpty, "Test expects there to be at least one jurisdiction defined")
            
            try milkyWayGalaxy.$jurisdictions.attach(allJurisdictions, on: self.database) { $0.id!.rank = 1 }.wait() // `Siblings.attach(_:on:)` uses array create.
            
            let milkyWayGalaxyReloaded = try XCTUnwrap(Galaxy.query(on: self.database).filter(\.$name == "Milky Way").with(\.$jurisdictions).with(\.$jurisdictions.$pivots).first().wait())
            XCTAssertEqual(milkyWayGalaxyReloaded.jurisdictions.count, allJurisdictions.count)
            
            try milkyWayGalaxyReloaded.$jurisdictions.pivots.delete(on: self.database).wait() // `Silbings.detach(_:on:)` does *not* use array delete, though, so do it ourselves.

            let milkyWayGalaxyRevolutions = try XCTUnwrap(Galaxy.query(on: self.database).filter(\.$name == "Milky Way").with(\.$jurisdictions).first().wait())
            XCTAssertEqual(milkyWayGalaxyRevolutions.jurisdictions.count, 0)
        }
    }
    
    private func testCompositeID_count() throws {
        try self.runTest(#function, [
            GalaxyMigration(),
            JurisdictionMigration(),
            GalacticJurisdictionMigration(),
            GalaxySeed(),
            JurisdictionSeed(),
            GalacticJurisdictionSeed(),
        ]) {
            let pivotCount = try GalacticJurisdiction.query(on: self.database).count().wait()
            
            XCTAssertGreaterThan(pivotCount, 0)
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
        CompositeIDModel.query(on: database).delete()
    }
}

