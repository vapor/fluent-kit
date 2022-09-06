#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension OptionalChildProperty {
    
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
    
    func create(_ to: To, on database: Database) async throws {
        try await self.create(to, on: database).get()
    }
}

#endif
