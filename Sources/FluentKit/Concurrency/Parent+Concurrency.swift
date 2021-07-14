#if compiler(>=5.5)
import _NIOConcurrency

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension ParentProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}

#endif

