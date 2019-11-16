import Foundation
@_exported import class NIO.NIOThreadPool

public final class Databases {
    public let eventLoopGroup: EventLoopGroup
    public let threadPool: NIOThreadPool
    
    private var drivers: [DatabaseID: DatabaseDriver]
    private var configurations: [DatabaseID: DatabaseConfiguration]
    private var _default: DatabaseDriver?
    
    public init(threadPool: NIOThreadPool, on eventLoopGroup: EventLoopGroup) {
        self.drivers = [:]
        self.configurations = [:]
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool
    }
    
    public func use(
        _ factory: DatabaseDriverFactory,
        as id: DatabaseID = .default
    ) {
        self.use(factory.makeDriver(self), as: id)
    }
    
    public func use(
        _ driver: DatabaseDriver,
        as id: DatabaseID = .default
    ) {
        self.drivers[id] = driver
        if self.configurations[id] == nil {
            self.configurations[id] = .init()
        }
    }
    
    public struct Middleware {
        let databases: Databases

        public func use(
            _ middleware: AnyModelMiddleware,
            on id: DatabaseID = .default
        ) {
            self.databases.configurations[id, default: .init()]
                .middleware
                .append(middleware)
        }
    }
    
    public var middleware: Middleware {
        .init(databases: self)
    }
    
    public func driver(_ id: DatabaseID = .default) -> DatabaseDriver? {
        self.drivers[id]
    }
    
    public func database(
        _ id: DatabaseID = .default,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> Database? {
        let context = DatabaseContext(
            configuration: self.configurations[id]!,
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
