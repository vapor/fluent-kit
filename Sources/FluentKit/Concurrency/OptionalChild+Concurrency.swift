import NIOCore

extension OptionalChildProperty {
    public func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }

    public func create(_ to: To, on database: any Database) async throws {
        try await self.create(to, on: database).get()
    }
}

extension CompositeOptionalChildProperty {
    public func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}
