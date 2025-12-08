import NIOCore

public extension ParentProperty {
    func load(on database: any Database) async throws {
        self.value = try await self.query(on: database).first()
    }
}

public extension CompositeParentProperty {
    func load(on database: any Database) async throws {
        self.value = try await self.query(on: database).first()
    }
}
