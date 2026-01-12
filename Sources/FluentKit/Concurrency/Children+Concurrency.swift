import NIOCore

public extension ChildrenProperty {
    func load(on database: any Database) async throws {
        self.value = try await self.query(on: database).all()
    }
    
    func create(_ to: To, on database: any Database) async throws {
        guard let id = self.idValue else {
            fatalError("Cannot save child in relation \(self.name) to unsaved model.")
        }
        switch self.parentKey {
        case .required(let keyPath):
            to[keyPath: keyPath].id = id
        case .optional(let keyPath):
            to[keyPath: keyPath].id = id
        }
        return try await to.create(on: database)
    }
    
    func create(_ to: [To], on database: any Database) async throws {
        guard let id = self.idValue else {
            fatalError("Cannot save child in relation \(self.name) to unsaved model.")
        }
        to.forEach {
            switch self.parentKey {
            case .required(let keyPath):
                $0[keyPath: keyPath].id = id
            case .optional(let keyPath):
                $0[keyPath: keyPath].id = id
            }
        }
        return try await to.create(on: database)
    }
}

public extension CompositeChildrenProperty {
    func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
}
