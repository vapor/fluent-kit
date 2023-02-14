import NIOCore

public extension SchemaBuilder {
    func create() async throws {
        try await self.create().get()
    }
    
    func update() async throws {
        try await self.update().get()
    }
    
    func delete() async throws {
        try await self.delete().get()
    }
}
