import NIOCore

public extension Relation {
    func get(reload: Bool = false, on database: any Database) async throws -> RelatedValue {
        try await self.get(reload: reload, on: database).get()
    }
}
