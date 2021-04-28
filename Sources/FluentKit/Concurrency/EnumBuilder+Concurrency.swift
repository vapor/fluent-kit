#if compiler(>=5.5) && $AsyncAwait
 import _NIOConcurrency

 @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
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
