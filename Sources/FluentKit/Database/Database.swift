public enum EventLoopPreference {
    case indifferent
    case delegate(on: EventLoop)
}

public class DatabaseContext {
    internal var middleware: [AnyModelMiddleware]
    
    init() {
        self.middleware = []
    }
    
    public func use(middleware: AnyModelMiddleware) {
        self.middleware.append(middleware)
    }
}

public protocol Database {
    var driver: DatabaseDriver { get }
    var logger: Logger { get }
    var eventLoopPreference: EventLoopPreference { get }
    var context: DatabaseContext { get }
}

private struct DriverOverrideDatabase: Database {
    var context: DatabaseContext {
        return self.base.context
    }
    
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
        switch self.eventLoopPreference {
        case .indifferent:
            return self.driver.eventLoopGroup.next()
        case .delegate(let eventLoop):
            return eventLoop
        }
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
