#if compiler(>=5.5)
import _NIOConcurrency

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension Relation {
    func get(reload: Bool = false, on database: Database) async throws -> RelatedValue {
        try await self.get(reload: reload, on: database).get()
    }
}

#endif
