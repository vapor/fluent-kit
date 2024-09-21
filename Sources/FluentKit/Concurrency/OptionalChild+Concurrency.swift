import NIOCore

public extension OptionalChildProperty {
    func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
    
    func create(_ to: To, on database: any Database) async throws {
        try await self.create(to, on: database).get()
    }
}

public extension CompositeOptionalChildProperty {
    func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}
