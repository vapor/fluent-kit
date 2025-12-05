import NIOCore

public extension OptionalParentProperty {
    func load(on database: any Database) async throws {
        self.value = try await self.query(on: database).first()
    }
}

public extension CompositeOptionalParentProperty {
    func load(on database: any Database) async throws {
        self.value = try await self.query(on: database).first()
    }
}
