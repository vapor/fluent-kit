#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
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

#endif
