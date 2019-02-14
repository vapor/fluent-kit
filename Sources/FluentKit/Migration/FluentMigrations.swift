public struct FluentMigrations {
    struct Item {
        var id: FluentDatabaseID?
        var migration: FluentMigration
    }
    
    var storage: [Item]
    
    public init() {
        self.storage = []
    }
    
    public mutating func add(_ migration: FluentMigration, to id: FluentDatabaseID? = nil) {
        self.storage.append(.init(id: id, migration: migration))
    }
}
