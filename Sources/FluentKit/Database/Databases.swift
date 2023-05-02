import Foundation
import struct NIOConcurrencyHelpers.NIOLock
import NIOCore
import NIOPosix
import Logging

public struct DatabaseConfigurationFactory {
    public let make: () -> DatabaseConfiguration

    public init(make: @escaping () -> DatabaseConfiguration) {
        self.make = make
    }
}

public final class Databases {
    public let eventLoopGroup: EventLoopGroup
    public let threadPool: NIOThreadPool

    private var configurations: [DatabaseID: DatabaseConfiguration]
    private var defaultID: DatabaseID?

    // Currently running database drivers.
    // Access to this variable must be synchronized.
    private var drivers: [DatabaseID: DatabaseDriver]

    // Synchronize access across threads.
    private var lock: NIOLock
    
    public struct Middleware {
        let databases: Databases

        public func use(
            _ middleware: AnyModelMiddleware,
            on id: DatabaseID? = nil
        ) {
            self.databases.lock.withLockVoid {
                let id = id ?? self.databases._requireDefaultID()
                var configuration = self.databases._requireConfiguration(for: id)
                configuration.middleware.append(middleware)
                self.databases.configurations[id] = configuration
            }
        }
        
        public func clear(on id: DatabaseID? = nil) {
            self.databases.lock.withLockVoid {
                let id = id ?? self.databases._requireDefaultID()
                var configuration = self.databases._requireConfiguration(for: id)
                configuration.middleware.removeAll()
                self.databases.configurations[id] = configuration
            }
        }
    }

    public var middleware: Middleware {
        .init(databases: self)
    }
    
    public init(threadPool: NIOThreadPool, on eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool
        self.configurations = [:]
        self.drivers = [:]
        self.lock = .init()
    }
    
    public func use(
        _ configuration: DatabaseConfigurationFactory,
        as id: DatabaseID,
        isDefault: Bool? = nil
    ) {
        self.use(configuration.make(), as: id, isDefault: isDefault)
    }
    
    public func use(
        _ driver: DatabaseConfiguration,
        as id: DatabaseID,
        isDefault: Bool? = nil
    ) {
        self.lock.withLockVoid {
            self.configurations[id] = driver
            if isDefault == true || (self.defaultID == nil && isDefault != false) {
                self.defaultID = id
            }
        }
    }

    public func `default`(to id: DatabaseID) {
        self.lock.withLockVoid {
            self.defaultID = id
        }
    }
    
    public func configuration(for id: DatabaseID? = nil) -> DatabaseConfiguration? {
        self.lock.withLock {
            self.configurations[id ?? self._requireDefaultID()]
        }
    }
    
    public func database(
        _ id: DatabaseID? = nil,
        logger: Logger,
        on eventLoop: EventLoop,
        history: QueryHistory? = nil,
        pageSizeLimit: Int? = nil
    ) -> Database? {
        self.lock.withLock {
            let id = id ?? self._requireDefaultID()
            var logger = logger
            logger[metadataKey: "database-id"] = .string(id.string)
            let configuration = self._requireConfiguration(for: id)
            let context = DatabaseContext(
                configuration: configuration,
                logger: logger,
                eventLoop: eventLoop,
                history: history,
                pageSizeLimit: pageSizeLimit
            )
            let driver: DatabaseDriver
            if let existing = self.drivers[id] {
                driver = existing
            } else {
                let new = configuration.makeDriver(for: self)
                self.drivers[id] = new
                driver = new
            }
            return driver.makeDatabase(with: context)
        }
    }

    public func reinitialize(_ id: DatabaseID? = nil) {
        self.lock.withLockVoid {
            let id = id ?? self._requireDefaultID()
            if let driver = self.drivers[id] {
                self.drivers[id] = nil
                driver.shutdown()
            }
        }
    }

    public func ids() -> Set<DatabaseID> {
        self.lock.withLock { Set(self.configurations.keys) }
    }

    public func shutdown() {
        self.lock.withLockVoid {
            for driver in self.drivers.values {
                driver.shutdown()
            }
            self.drivers = [:]
        }
    }

    private func _requireConfiguration(for id: DatabaseID) -> DatabaseConfiguration {
        guard let configuration = self.configurations[id] else {
            fatalError("No datatabase configuration registered for \(id).")
        }
        return configuration
    }
    
    private func _requireDefaultID() -> DatabaseID {
        guard let id = self.defaultID else {
            fatalError("No default database configured.")
        }
        return id
    }
}
