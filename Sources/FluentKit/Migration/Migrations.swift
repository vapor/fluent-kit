import NIOConcurrencyHelpers

public protocol MigrationsGroup {
    var migrations : [any Migration] { get set }
} 

public final class Migrations: Sendable {
    let storage: NIOLockedValueBox<[DatabaseID?: [any Migration]]>

    public init() {
        self.storage = .init([:])
    }
    
    public func add(_ migration: any Migration, to id: DatabaseID? = nil) {
        self.storage.withLockedValue { $0[id, default: []].append(migration) }
    }
    
    @inlinable
    public func add(_ migrations: any Migration..., to id: DatabaseID? = nil) {
        self.add(migrations, to: id)
    }

    public func add(_ migrations: [any Migration], to id: DatabaseID? = nil) {
        self.storage.withLockedValue { $0[id, default: []].append(contentsOf: migrations) }
    }

    public func addGroup(_ group: any MigrationsGroup, to id: DatabaseID? = nil) { 
        for migration in group.migrations {
            self.add(migration, to: id)
        }
    }
}
