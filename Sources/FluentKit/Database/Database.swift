
public enum EventLoopPreference {
    case any
    case prefer(EventLoop)
    
    public func on(_ group: EventLoopGroup) -> EventLoop {
        switch self {
        case .any:
            return group.next()
        case .prefer(let eventLoop):
            return eventLoop
        }
    }
}

public protocol Database {
    var driver: DatabaseDriver { get }
    var logger: Logger? { get }
    var eventLoopPreference: EventLoopPreference { get }
}

extension Database {
    public func withConnection<T>(
        _ closure: @escaping (Database) -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        return self.driver.withConnection(eventLoop: self.eventLoopPreference) { driver in
            return closure(DriverOverrideDatabase(base: self, driver: driver))
        }
    }
}

private struct DriverOverrideDatabase: Database {
    var logger: Logger? {
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
        case .any:
            return self.driver.eventLoopGroup.next()
        case .prefer(let eventLoop):
            return eventLoop
        }
    }
}

public protocol DatabaseDriver {
    var eventLoopGroup: EventLoopGroup { get }

    func execute(
        _ query: DatabaseQuery,
        eventLoop: EventLoopPreference,
        _ onOutput: @escaping (DatabaseOutput) throws -> ()
    ) -> EventLoopFuture<Void>

    func execute(
        _ schema: DatabaseSchema,
        eventLoop: EventLoopPreference
    ) -> EventLoopFuture<Void>

    func withConnection<T>(
        eventLoop: EventLoopPreference,
        _ closure: @escaping (DatabaseDriver) -> EventLoopFuture<T>
    ) -> EventLoopFuture<T>

    func shutdown()
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
