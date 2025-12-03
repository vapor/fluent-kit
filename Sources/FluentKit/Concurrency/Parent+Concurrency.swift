import NIOCore

extension ParentProperty {
    public func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}

extension CompositeParentProperty {
    public func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}
