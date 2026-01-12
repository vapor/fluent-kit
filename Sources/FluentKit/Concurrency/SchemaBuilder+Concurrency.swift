import NIOCore

public extension SchemaBuilder {
    func create() async throws {
        self.schema.action = .create
        return try await self.database.execute(schema: self.schema)
    }
    
    func update() async throws {
        self.schema.action = .update
        return try await self.database.execute(schema: self.schema)
    }
    
    func delete() async throws {
        self.schema.action = .delete
        return try await self.database.execute(schema: self.schema)
    }
}
