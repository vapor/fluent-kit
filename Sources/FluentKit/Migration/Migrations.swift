public final class Migrations {
    struct Item {
        var id: DatabaseID?
        var migration: Migration
    }
    
    var storage: [Item]
    var databases: Set<DatabaseID?> { Set(self.storage.map(\.id)) }
    
    public init() {
        self.storage = []
    }
    
    public func add(_ migration: Migration, to id: DatabaseID? = nil) {
        self.storage.append(.init(id: id, migration: migration))
    }
    
    @inlinable
    public func add(_ migrations: Migration..., to id: DatabaseID? = nil) {
        self.add(migrations, to: id)
    }

    public func add(_ migrations: [Migration], to id: DatabaseID? = nil) {
        self.storage.append(contentsOf: migrations.map { .init(id: id, migration: $0) })
    }
}
