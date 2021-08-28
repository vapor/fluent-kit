public final class Migrations {
    var storage: [DatabaseID?: [Migration]]
    
    public init() {
        self.storage = [:]
    }
    
    public func add(_ migration: Migration, to id: DatabaseID? = nil) {
        self.storage[id, default: []].append(migration)
    }
    
    @inlinable
    public func add(_ migrations: Migration..., to id: DatabaseID? = nil) {
        self.add(migrations, to: id)
    }

    public func add(_ migrations: [Migration], to id: DatabaseID? = nil) {
        self.storage[id, default: []].append(contentsOf: migrations)
    }
}
