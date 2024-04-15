public final class Migrations {
    var storage: [DatabaseID?: [any Migration]]
    
    public init() {
        self.storage = [:]
    }
    
    public func add(_ migration: any Migration, to id: DatabaseID? = nil) {
        self.storage[id, default: []].append(migration)
    }
    
    @inlinable
    public func add(_ migrations: any Migration..., to id: DatabaseID? = nil) {
        self.add(migrations, to: id)
    }

    public func add(_ migrations: [any Migration], to id: DatabaseID? = nil) {
        self.storage[id, default: []].append(contentsOf: migrations)
    }
}
