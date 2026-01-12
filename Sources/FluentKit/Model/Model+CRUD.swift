import NIOCore
import protocol SQLKit.SQLDatabase

extension Model {
    public func save(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.save(on: database)
        }
    }

    public func create(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.create(on: database)
        }
    }
    
    public func update(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.update(on: database)
        }
    }

    public func delete(force: Bool = false, on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.delete(force: force, on: database)
        }
    }

    public func restore(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.restore(on: database)
        }
    }
}

extension Collection where Element: FluentKit.Model, Self: Sendable {
    public func delete(force: Bool = false, on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.delete(force: force, on: database)
        }
    }

    public func create(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.create(on: database)
        }
    }
}

public enum MiddlewareFailureHandler {
    /// Insert objects which middleware did not fail
    case insertSucceeded
    /// If a failure has occurs in a middleware, none of the models are saved and the first failure is returned.
    case failOnFirst
}

// MARK: Private

struct SavedInput: DatabaseOutput {
    var input: [FieldKey: DatabaseQuery.Value]
    
    init(_ input: [FieldKey: DatabaseQuery.Value]) {
        self.input = input
    }

    func schema(_ schema: String) -> any DatabaseOutput {
        self
    }
    
    func contains(_ key: FieldKey) -> Bool {
        self.input[key] != nil
    }

    func nested(_ key: FieldKey) throws -> any DatabaseOutput {
        guard let data = self.input[key] else {
            throw FluentError.missingField(name: key.description)
        }
        guard case .dictionary(let nested) = data else {
            fatalError("Unexpected input: \(data).")
        }
        return SavedInput(nested)
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        guard let value = self.input[key] else {
            throw FluentError.missingField(name: key.description)
        }
        switch value {
        case .null:
            return true
        default:
            return false
        }
    }
    
    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T : Decodable
    {
        guard let value = self.input[key] else {
            throw FluentError.missingField(name: key.description)
        }
        switch value {
        case .bind(let encodable):
            return encodable as! T
        case .enumCase(let string):
            return string as! T
        default:
            fatalError("Invalid input type: \(value)")
        }
    }

    var description: String {
        self.input.description
    }
}
