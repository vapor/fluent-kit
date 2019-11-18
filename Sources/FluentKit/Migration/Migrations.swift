public struct Migrations {
    struct Item {
        var id: DatabaseID?
        var migration: Migration
    }
    
    var storage: [Item]
    
    public init() {
        self.storage = []
    }
    
    public mutating func add(_ migration: Migration, to id: DatabaseID? = nil) {
        self.storage.append(.init(id: id, migration: migration))
    }
}
