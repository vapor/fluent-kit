import Foundation

public final class Databases {
    private var storage: [DatabaseID: Database]
    private var _default: Database?
    
    public init() {
        self.storage = [:]
    }
    
    public func add(
        _ driver: DatabaseDriver,
        logger: Logger = .init(label: "codes.vapor.db"),
        as id: DatabaseID,
        isDefault: Bool = true
    ) {
        let db = BasicDatabase(driver: driver, logger: logger)
        self.storage[id] = db
        if isDefault {
            self._default = db
        }
    }
    
    public func database(_ id: DatabaseID) -> Database? {
        return self.storage[id]
    }
    
    public func `default`() -> Database {
        return self._default!
    }

    public func shutdown() {
        for db in self.storage.values {
            db.driver.shutdown()
        }
    }
}

private struct BasicDatabase: Database {
    var eventLoopPreference: EventLoopPreference {
        return .indifferent
    }

    let driver: DatabaseDriver
    let logger: Logger
}
