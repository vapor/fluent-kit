import NIOCore

public extension OptionalParentProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}

public extension CompositeOptionalParentProperty {
    func load(on database: Database) async throws {
        try await self.load(on: database).get()
    }
}
