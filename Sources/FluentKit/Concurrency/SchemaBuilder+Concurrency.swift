#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
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
