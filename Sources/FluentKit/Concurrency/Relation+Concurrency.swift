#if compiler(>=5.5) && $AsyncAwait
 import _NIOConcurrency

 @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
 public extension Relation {
    func get(reload: Bool = false, on database: Database) async throws -> RelatedValue {
        try await self.get(reload: reload, on: database).get()
    }
 }

 #endif
