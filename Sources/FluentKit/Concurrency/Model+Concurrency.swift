#if compiler(>=5.5) && $AsyncAwait
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public extension Model {
    static func find(
        _ id: Self.IDValue?,
        on database: Database
    ) async throws -> Self? {
        try await self.find(id, on: database).get()
    }

    // MARK: - CRUD
    func save(on database: Database) async throws {
        try await self.save(on: database).get()
    }

    func create(on database: Database) async throws {
        try await self.create(on: database).get()
    }

    func update(on database: Database) async throws {
        try await self.update(on: database).get()
    }

    func delete(force: Bool = false, on database: Database) async throws {
        try await self.delete(force: force, on: database).get()
    }

    func restore(on database: Database) async throws {
        try await self.restore(on: database).get()
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public extension Collection where Element: FluentKit.Model {
    func delete(force: Bool = false, on database: Database) async throws {
        try await self.delete(force: force, on: database).get()
    }

    func create(on database: Database) async throws {
        try await self.create(on: database).get()
    }
}

#endif
