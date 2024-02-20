import FluentKit
import Foundation
import NIOCore

public final class GalacticJurisdiction: Model {
    public static let schema = "galaxy_jurisdictions"
    
    public final class IDValue: Fields, Hashable {
        @Parent(key: "galaxy_id")
        public var galaxy: Galaxy
        
        @Parent(key: "jurisdiction_id")
        public var jurisdiction: Jurisdiction
        
        @Field(key: "rank")
        public var rank: Int
        
        public init() {}
        
        public convenience init(galaxy: Galaxy, jurisdiction: Jurisdiction, rank: Int) throws {
            try self.init(galaxyId: galaxy.requireID(), jurisdictionId: jurisdiction.requireID(), rank: rank)
        }
        
        public init(galaxyId: Galaxy.IDValue, jurisdictionId: Jurisdiction.IDValue, rank: Int) {
            self.$galaxy.id = galaxyId
            self.$jurisdiction.id = jurisdictionId
            self.rank = rank
        }
        
        public static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.$galaxy.id == rhs.$galaxy.id && lhs.$jurisdiction.id == rhs.$jurisdiction.id && lhs.rank == rhs.rank
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.$galaxy.id)
            hasher.combine(self.$jurisdiction.id)
            hasher.combine(self.rank)
        }
    }
    
    @CompositeID()
    public var id: IDValue?
    
    public init() {}
    
    public init(id: IDValue) {
        self.id = id
    }
}

public struct GalacticJurisdictionMigration: Migration {
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(GalacticJurisdiction.schema)
            .field("galaxy_id", .uuid, .required, .references(Galaxy.schema, .id, onDelete: .cascade, onUpdate: .cascade))
            .field("jurisdiction_id", .uuid, .required, .references(Jurisdiction.schema, .id, onDelete: .cascade, onUpdate: .cascade))
            .field("rank", .int, .required)
            .compositeIdentifier(over: "galaxy_id", "jurisdiction_id", "rank")
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(GalacticJurisdiction.schema)
            .delete()
    }
}

public struct GalacticJurisdictionSeed: Migration {
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatSubmit {
            Galaxy.query(on: database).all().and(
            Jurisdiction.query(on: database).all())
        }.flatMap { galaxies, jurisdictions in
            [
                ("Milky Way", "Old", 0),
                ("Milky Way", "Corporate", 1),
                ("Andromeda", "Military", 0),
                ("Andromeda", "Corporate", 1),
                ("Andromeda", "None", 2),
                ("Pinwheel Galaxy", "Q", 0),
                ("Messier 82", "None", 0),
                ("Messier 82", "Military", 1),
            ]
            .sequencedFlatMapEach(on: database.eventLoop) { galaxyName, jurisdictionName, rank in
                GalacticJurisdiction.init(id: try! .init(
                    galaxy: galaxies.first(where: { $0.name == galaxyName })!,
                    jurisdiction: jurisdictions.first(where: { $0.title == jurisdictionName })!,
                    rank: rank
                )).create(on: database)
            }
        }
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        GalacticJurisdiction.query(on: database).delete()
    }
}
