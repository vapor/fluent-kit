#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension SiblingsProperty {
    
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
    
    // MARK: Checking state
    
    func isAttached(to: To, on database: Database) async throws -> Bool {
        try await self.isAttached(to: to, on: database).get()
    }
    
    func isAttached(toID: To.IDValue, on database: Database) async throws -> Bool {
        try await self.isAttached(toID: toID, on: database).get()
    }
    
    // MARK: Operations
    
    func attach(
        _ tos: [To],
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) async throws {
        try await self.attach(tos, on: database, edit).get()
    }
    
    func attach(
        _ to: To,
        method: AttachMethod,
        on database: Database,
        _ edit: @escaping (Through) -> () = { _ in }
    ) async throws {
        try await self.attach(to, method: method, on: database, edit).get()
    }
    
    func attach(
        _ to: To,
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) async throws {
        try await self.attach(to, on: database, edit).get()
    }
    
    
    func detach(_ tos: [To], on database: Database) async throws {
        try await self.detach(tos, on: database).get()
    }
    
    func detach(_ to: To, on database: Database) async throws {
        try await self.detach(to, on: database).get()
    }
    
    func detachAll(on database: Database) async throws {
        try await self.detachAll(on: database).get()
    }
}

#endif
