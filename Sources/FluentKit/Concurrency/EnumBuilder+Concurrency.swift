import NIOCore

extension EnumBuilder {
    public func create() async throws -> DatabaseSchema.DataType {
        try await self.create().get()
    }

    public func read() async throws -> DatabaseSchema.DataType {
        try await self.read().get()
    }

    public func update() async throws -> DatabaseSchema.DataType {
        try await self.update().get()
    }

    public func delete() async throws {
        try await self.delete().get()
    }
}
