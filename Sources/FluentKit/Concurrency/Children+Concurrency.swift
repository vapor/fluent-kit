#if compiler(>=5.5) && $AsyncAwait
 import _NIOConcurrency

 @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
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
