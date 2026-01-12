import NIOCore

public extension OptionalChildProperty {
    func load(on database: any Database) async throws {
        self.value = try await self.query(on: database).first()
    }
    
    func create(_ to: To, on database: any Database) async throws {
        guard let id = self.idValue else {
            fatalError("Cannot save child in \(self.name) to unsaved model in.")
        }
        switch self.parentKey {
        case .required(let keyPath):
            to[keyPath: keyPath].id = id
        case .optional(let keyPath):
            to[keyPath: keyPath].id = id
        }
        return try await to.create(on: database)
    }
}

public extension CompositeOptionalChildProperty {
    func load(on database: any Database) async throws {
        self.value = try await self.query(on: database).first()
    }
}
