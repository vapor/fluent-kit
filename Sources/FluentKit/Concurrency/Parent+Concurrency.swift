import NIOCore

public extension ParentProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}

public extension CompositeParentProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}
