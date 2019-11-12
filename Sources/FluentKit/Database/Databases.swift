import Foundation

public final class Databases {
    public let eventLoopGroup: EventLoopGroup
    private var storage: [DatabaseID: DatabaseDriver]
    private var _default: DatabaseDriver?
    
    public init(on eventLoopGroup: EventLoopGroup) {
        self.storage = [:]
        self.eventLoopGroup = eventLoopGroup
    }
    
    public func add(
        _ driver: DatabaseDriver,
        as id: DatabaseID,
        isDefault: Bool = true
    ) {
        self.storage[id] = driver
        if isDefault {
            self.storage[.default] = driver
        }
    }
    
    public func driver(_ id: DatabaseID = .default) -> DatabaseDriver? {
        self.storage[id]
    }
    
    public func database(
        _ id: DatabaseID = .default,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> Database? {
        self.driver(id).flatMap {
            $0.makeDatabase(with: .init(logger: logger, on: eventLoop))
        }
    }

    public func shutdown() {
        for driver in self.storage.values {
            driver.shutdown()
        }
    }
}
