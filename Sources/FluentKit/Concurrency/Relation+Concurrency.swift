import NIOCore

public extension Relation {
    func get(reload: Bool = false, on database: any Database) async throws -> RelatedValue {
        if let value = self.value, !reload {
            return value
        } else {
            try await self.load(on: database).get() // Ideally this would get an async version too
            guard let value = value else {  // This should never actually happen, but just in case...
                throw FluentError.relationNotLoaded(name: self.name)
            }
            return value
        }
    }
}
