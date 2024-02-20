import NIOCore

public extension EnumBuilder {
    func create() async throws -> DatabaseSchema.DataType {
        try await self.create().get()
    }
    
    func read() async throws -> DatabaseSchema.DataType {
        try await self.read().get()
    }
    
    func update() async throws -> DatabaseSchema.DataType {
        try await self.update().get()
    }
    
    func delete() async throws {
        try await self.delete().get()
    }
}
