import NIOCore

extension OptionalParentProperty {
    public func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}

extension CompositeOptionalParentProperty {
    public func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}
