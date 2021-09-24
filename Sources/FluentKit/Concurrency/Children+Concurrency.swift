#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension ChildrenProperty {
    
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
    
    func create(_ to: To, on database: Database) async throws {
        try await self.create(to, on: database).get()
    }
    
    func create(_ to: [To], on database: Database) async throws {
        try await self.create(to, on: database).get()
    }
}

#endif
