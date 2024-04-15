import NIOCore

public extension Model {
    static func find(
        _ id: Self.IDValue?,
        on database: any Database
    ) async throws -> Self? {
        try await self.find(id, on: database).get()
    }
    
    // MARK: - CRUD
    func save(on database: any Database) async throws {
        try await self.save(on: database).get()
    }
    
    func create(on database: any Database) async throws {
        try await self.create(on: database).get()
    }
    
    func update(on database: any Database) async throws {
        try await self.update(on: database).get()
    }
    
    func delete(force: Bool = false, on database: any Database) async throws {
        try await self.delete(force: force, on: database).get()
    }
    
    func restore(on database: any Database) async throws {
        try await self.restore(on: database).get()
    }
}

public extension Collection where Element: FluentKit.Model {
    func delete(force: Bool = false, on database: any Database) async throws {
        try await self.delete(force: force, on: database).get()
    }
    
    func create(on database: any Database) async throws {
        try await self.create(on: database).get()
    }
}
