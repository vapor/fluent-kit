#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension ParentProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}

#endif

