#if compiler(>=5.5) && $AsyncAwait
 import _NIOConcurrency

 @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
 public extension Model {
    static func find(
        _ id: Self.IDValue?,
        on database: Database
    ) async throws -> Self? {
        try await self.find(id, on: database).get()
    }
 }

 #endif
