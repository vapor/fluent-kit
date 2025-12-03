import NIOCore

extension SchemaBuilder {
    public func create() async throws {
        try await self.create().get()
    }

    public func update() async throws {
        try await self.update().get()
    }

    public func delete() async throws {
        try await self.delete().get()
    }
}
