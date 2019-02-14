import Foundation

public struct FluentDatabases {
    private var storage: [FluentDatabaseID: FluentDatabase]
    
    private var _default: FluentDatabase?
    
    public init() {
        self.storage = [:]
    }
    
    public mutating func add(_ database: FluentDatabase, as id: FluentDatabaseID, isDefault: Bool = true) {
        self.storage[id] = database
        if isDefault {
            self._default = database
        }
    }
    
    public func database(_ id: FluentDatabaseID) -> FluentDatabase? {
        return self.storage[id]
    }
    
    public func `default`() -> FluentDatabase {
        return self._default!
    }
}
