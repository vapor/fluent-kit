import Foundation
@_exported import class NIO.NIOThreadPool

public final class Databases {
    public let eventLoopGroup: EventLoopGroup
    public let threadPool: NIOThreadPool
    
    private var drivers: [DatabaseID: DatabaseDriver]
    private var configurations: [DatabaseID: DatabaseConfiguration]
    
    private var defaultID: DatabaseID?
    
    public init(threadPool: NIOThreadPool, on eventLoopGroup: EventLoopGroup) {
        self.drivers = [:]
        self.configurations = [:]
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool
    }
    
    public func use(
        _ factory: DatabaseDriverFactory,
        as id: DatabaseID,
        isDefault: Bool? = nil
    ) {
        self.use(factory.makeDriver(self), as: id, isDefault: isDefault)
    }
    
    public func use(
        _ driver: DatabaseDriver,
        as id: DatabaseID,
        isDefault: Bool? = nil
    ) {
        self.drivers[id] = driver
        if self.configurations[id] == nil {
            self.configurations[id] = .init()
        }
        if isDefault == true || self.defaultID == nil && isDefault != false {
            self.defaultID = id
        }
    }
    
    public struct Middleware {
        let databases: Databases

        public func use(
            _ middleware: AnyModelMiddleware,
            on id: DatabaseID
        ) {
            self.databases.configurations[id, default: .init()]
                .middleware
                .append(middleware)
        }
    }
    
    public var middleware: Middleware {
        .init(databases: self)
    }
    
    public func driver(_ id: DatabaseID? = nil) -> DatabaseDriver? {
        self.drivers[id ?? self.getDefaultID()]
    }
    
    public func `default`(to id: DatabaseID) {
        self.defaultID = id
    }
    
    public func database(
        _ id: DatabaseID? = nil,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> Database? {
        let id = id ?? self.getDefaultID()
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
    
    private func getDefaultID() -> DatabaseID {
        guard let id = self.defaultID else {
            fatalError("No default database configured.")
        }
        return id
    }
}

public struct DatabaseDriverFactory {
    public let makeDriver: (Databases) -> DatabaseDriver
    
    public init(makeDriver: @escaping (Databases) -> DatabaseDriver) {
        self.makeDriver = makeDriver
    }
}
