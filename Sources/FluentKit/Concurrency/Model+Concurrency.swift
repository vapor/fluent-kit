import NIOCore

extension Model {
    public static func find(
        _ id: Self.IDValue?,
        on database: any Database
    ) async throws -> Self? {
        try await self.find(id, on: database).get()
    }

    // MARK: - CRUD
    public func save(on database: any Database) async throws {
        try await self.save(on: database).get()
    }

    public func create(on database: any Database) async throws {
        try await self.create(on: database).get()
    }

    public func update(on database: any Database) async throws {
        try await self.update(on: database).get()
    }

    public func delete(force: Bool = false, on database: any Database) async throws {
        try await self.delete(force: force, on: database).get()
    }

    public func restore(on database: any Database) async throws {
        try await self.restore(on: database).get()
    }
}

extension Collection where Element: FluentKit.Model, Self: Sendable {
    public func delete(force: Bool = false, on database: any Database) async throws {
        try await self.delete(force: force, on: database).get()
    }

    public func create(on database: any Database) async throws {
        try await self.create(on: database).get()
    }
}
