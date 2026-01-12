import NIOCore
import NIOConcurrencyHelpers
import SQLKit

extension Database {
    public func `enum`(_ name: String) -> EnumBuilder {
        .init(database: self, name: name)
    }
}

public final class EnumBuilder: Sendable {
    let database: any Database
    let lockedEnum: NIOLockedValueBox<DatabaseEnum>

    public var `enum`: DatabaseEnum {
        get { self.lockedEnum.withLockedValue { $0 } }
        set { self.lockedEnum.withLockedValue { $0 = newValue } }
    }

    init(database: any Database, name: String) {
        self.database = database
        self.lockedEnum = .init(.init(name: name))
    }

    public func `case`(_ name: String) -> Self {
        self.enum.createCases.append(name)
        return self
    }

    public func deleteCase(_ name: String) -> Self {
        self.enum.deleteCases.append(name)
        return self
    }

    public func create() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.database.eventLoop.makeFutureWithTask {
            try await self.create()
        }
    }

    public func read() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.database.eventLoop.makeFutureWithTask {
            try await self.generateDatatype()
        }
    }

    public func update() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.database.eventLoop.makeFutureWithTask {
            try await self.update()
        }
    }

    public func delete() -> EventLoopFuture<Void> {
        self.database.eventLoop.makeFutureWithTask {
            try await self.delete()
        }
    }
}
