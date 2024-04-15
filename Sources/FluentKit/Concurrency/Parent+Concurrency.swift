import NIOCore

public extension ParentProperty {
    func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}

public extension CompositeParentProperty {
    func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}
