import Foundation
@_exported import class NIO.NIOThreadPool

public struct Databases {
    public struct Middleware {
        var storage: [DatabaseID: [AnyModelMiddleware]]
        
        init() {
            self.storage = [:]
        }
        
        public mutating func use(
            _ middleware: AnyModelMiddleware,
            on id: DatabaseID = .default
        ) {
            self.storage[id, default: []].append(middleware)
        }
    }
    
    public let eventLoopGroup: EventLoopGroup
    public let threadPool: NIOThreadPool
    public var middleware: Middleware
    
    private var drivers: [DatabaseID: DatabaseDriver]
    private var _default: DatabaseDriver?
    
    public init(threadPool: NIOThreadPool, on eventLoopGroup: EventLoopGroup) {
        self.drivers = [:]
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool
        self.middleware = .init()
    }
    
    public mutating func use(
        _ factory: DatabaseDriverFactory,
        as id: DatabaseID = .default
    ) {
        self.use(factory.makeDriver(self), as: id)
    }
    
    public mutating func use(
        _ driver: DatabaseDriver,
        as id: DatabaseID = .default
    ) {
        self.drivers[id] = driver
    }
    
    public func driver(_ id: DatabaseID = .default) -> DatabaseDriver? {
        self.drivers[id]
    }
    
    public func database(
        _ id: DatabaseID = .default,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> Database? {
        let configuration = DatabaseConfiguration()
        configuration.middleware = self.middleware.storage[id] ?? []
        let context = DatabaseContext(
            configuration: configuration,
            logger: logger,
            eventLoop: eventLoop
        )
        return self.driver(id).flatMap { driver in
            driver.makeDatabase(with: context)
        }
    }

    public func shutdown() {
        for driver in self.drivers.values {
            driver.shutdown()
        }
    }
}

public struct DatabaseDriverFactory {
    public let makeDriver: (Databases) -> DatabaseDriver
    
    public init(makeDriver: @escaping (Databases) -> DatabaseDriver) {
        self.makeDriver = makeDriver
    }
}
