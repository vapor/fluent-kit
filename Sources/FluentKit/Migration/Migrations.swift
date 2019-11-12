public final class Migrations {
    struct Item {
        var id: DatabaseID?
        var migration: Migration
    }
    
    var storage: [Item]
    
    public init() {
        self.storage = []
    }
    
    public func add(_ migration: Migration, to id: DatabaseID? = nil) {
        self.storage.append(.init(id: id, migration: migration))
    }
}
