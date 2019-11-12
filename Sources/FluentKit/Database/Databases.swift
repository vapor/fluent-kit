import Foundation

public final class Databases {
    public let eventLoopGroup: EventLoopGroup
    private var drivers: [DatabaseID: DatabaseDriver]
    private var contexts: [DatabaseID: DatabaseContext]
    private var _default: DatabaseDriver?
    
    public init(on eventLoopGroup: EventLoopGroup) {
        self.drivers = [:]
        self.contexts = [:]
        self.eventLoopGroup = eventLoopGroup
    }
    
    public func add(
        _ driver: DatabaseDriver,
        as id: DatabaseID,
        isDefault: Bool = true
    ) {
        self.drivers[id] = driver
        if isDefault {
            self.drivers[.default] = driver
        }
    }
    
    public func add(
        _ middleware: AnyModelMiddleware,
        to id: DatabaseID = .default
    ) {
        self.contexts[id, default: .init()].middleware.append(middleware)
    }
    
    public func driver(_ id: DatabaseID = .default) -> DatabaseDriver? {
        self.drivers[id]
    }
    
    public func database(
        _ id: DatabaseID = .default,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> Database? {
        self.driver(id).flatMap { driver in
            driver.makeDatabase(
                logger: logger,
                context: self.contexts[id] ?? .init(),
                on: eventLoop
            )
        }
    }

    public func shutdown() {
        for driver in self.drivers.values {
            driver.shutdown()
        }
    }
}
