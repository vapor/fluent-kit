#if compiler(>=5.5) && $AsyncAwait
 import _NIOConcurrency

 @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
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
