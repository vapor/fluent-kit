import Foundation

public struct Databases {
    private var storage: [DatabaseID: DatabaseDriver]
    private var _default: DatabaseDriver?
    
    public init() {
        self.storage = [:]
    }
    
    public mutating func add(_ database: DatabaseDriver, as id: DatabaseID, isDefault: Bool = true) {
        self.storage[id] = database
        if isDefault {
            self._default = database
        }
    }
    
    public func database(_ id: DatabaseID) -> Database? {
        return self.storage[id].flatMap { BasicDatabase(driver: $0) }
    }
    
    public func `default`() -> Database {
        return BasicDatabase(driver: self._default!)
    }

    public func shutdown() {
        for driver in self.storage.values {
            driver.shutdown()
        }
    }
}

private struct BasicDatabase: Database {
    var logger: Logger? {
        return nil
    }

    var eventLoopPreference: EventLoopPreference {
        return .any
    }

    let driver: DatabaseDriver
    init(driver: DatabaseDriver) {
        self.driver = driver
    }
}
