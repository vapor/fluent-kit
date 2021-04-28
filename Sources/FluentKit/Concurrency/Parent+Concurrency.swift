#if compiler(>=5.5) && $AsyncAwait
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public extension ParentProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}

#endif

