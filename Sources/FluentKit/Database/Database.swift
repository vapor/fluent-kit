
public enum EventLoopPreference {
    case indifferent
    case delegate(on: EventLoop)
    
    public func on(_ group: EventLoopGroup) -> EventLoop {
        switch self {
        case .indifferent:
            return group.next()
        case .delegate(let eventLoop):
            return eventLoop
        }
    }
}

public protocol Database {
    var driver: DatabaseDriver { get }
    var logger: Logger { get }
    var eventLoopPreference: EventLoopPreference { get }
}

private struct DriverOverrideDatabase: Database {
    var logger: Logger {
        return self.base.logger
    }
    
    var eventLoopPreference: EventLoopPreference {
        return self.base.eventLoopPreference
    }
    
    let base: Database
    let driver: DatabaseDriver
    
    init(base: Database, driver: DatabaseDriver) {
        self.base = base
        self.driver = driver
    }
}

extension Database {
    public var eventLoop: EventLoop {
        self.eventLoopPreference.on(self.driver.eventLoopGroup)
    }
    
    var hopEventLoop: EventLoop? {
        switch self.eventLoopPreference {
        case .delegate(let eventLoop):
            if !eventLoop.inEventLoop {
                return eventLoop
            } else {
                return nil
            }
        case .indifferent:
            return nil
        }
    }
}

public protocol DatabaseDriver {
    var eventLoopGroup: EventLoopGroup { get }

    func execute(
        query: DatabaseQuery,
        database: Database,
        onRow: @escaping (DatabaseRow) -> ()
    ) -> EventLoopFuture<Void>

    func execute(
        schema: DatabaseSchema,
        database: Database
    ) -> EventLoopFuture<Void>

    func shutdown()
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
