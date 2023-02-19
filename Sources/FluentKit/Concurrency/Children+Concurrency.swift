import NIOCore

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

public extension CompositeChildrenProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}
