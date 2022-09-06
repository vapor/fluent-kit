#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Relation {
    func get(reload: Bool = false, on database: Database) async throws -> RelatedValue {
        try await self.get(reload: reload, on: database).get()
    }
}

#endif
