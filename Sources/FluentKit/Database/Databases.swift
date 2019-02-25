import Foundation

public struct Databases {
    private var storage: [DatabaseID: Database]
    
    private var _default: Database?
    
    public let eventLoop: EventLoop
    
    public init(on eventLoop: EventLoop) {
        self.storage = [:]
        self.eventLoop = eventLoop
    }
    
    public mutating func add(_ database: Database, as id: DatabaseID, isDefault: Bool = true) {
        self.storage[id] = database
        if isDefault {
            self._default = database
        }
    }
    
    public func database(_ id: DatabaseID) -> Database? {
        return self.storage[id]
    }
    
    public func `default`() -> Database {
        return self._default!
    }
}
