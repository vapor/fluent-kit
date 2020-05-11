public final class Migrations {
    struct Item {
        var id: DatabaseID?
        var migration: Migration
    }
    
    var storage: [Item]
    var databases: Set<DatabaseID>
    
    public init() {
        self.storage = []
        self.databases = []
    }
    
    public func add(_ migration: Migration, to id: DatabaseID? = nil) {
        self.storage.append(.init(id: id, migration: migration))
        if let id = id { self.databases.insert(id) }
    }
}
