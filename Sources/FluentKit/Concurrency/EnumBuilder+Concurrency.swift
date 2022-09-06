#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
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

#endif
