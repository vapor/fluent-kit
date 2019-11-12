import Foundation

public final class Databases {
    public let eventLoopGroup: EventLoopGroup
    private var storage: [DatabaseID: DatabaseDriver]
    private var middlewares: [DatabaseID: [AnyModelMiddleware]]
    private var _default: DatabaseDriver?
    
    public init(on eventLoopGroup: EventLoopGroup) {
        self.storage = [:]
        self.eventLoopGroup = eventLoopGroup
        self.middlewares = [:]
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
    
    public func add(
        _ middleware: AnyModelMiddleware,
        to id: DatabaseID = .default
    ) {
        self.middlewares[id, default: []].append(middleware)
    }
    
    public func driver(_ id: DatabaseID = .default) -> DatabaseDriver? {
        self.storage[id]
    }
    
    public func database(
        _ id: DatabaseID = .default,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> Database? {
        self.driver(id).flatMap { driver in
            let context = DatabaseContext(logger: logger, on: eventLoop)
            context.middleware = self.middlewares[id] ?? []
            return driver.makeDatabase(with: context)
        }
    }

    public func shutdown() {
        for driver in self.storage.values {
            driver.shutdown()
        }
    }
}
