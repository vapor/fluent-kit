import NIOCore
import protocol SQLKit.SQLDatabase

extension Model {
    public func save(on database: any Database) async throws {
        if self._$idExists {
            try await self.update(on: database)
        } else {
            try await self.create(on: database)
        }
    }

    public func create(on database: any Database) async throws {
        try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try await model.handle(event, on: db)
        }.handle(.create, self, on: database)
    }

    private func _create(on database: any Database) async throws {
        precondition(!self._$idExists)
        self.touchTimestamps(.create, .update)
        if self.anyID is any AnyQueryableProperty {
            self.anyID.generate()
            var output: (any DatabaseOutput)?
            for try await element in try await Self.query(on: database)
                .set(self.collectInput(withDefaultedValues: database is any SQLDatabase))
                .action(.create)
                .run()
            {
                output = element
                break
            }
            guard let output else {
                throw FluentError.noResults
            }

            var input = self.collectInput()
            if case .default = self._$id.inputValue {
                let idKey = Self()._$id.key
                input[idKey] = try .bind(output.decode(idKey, as: Self.IDValue.self))
            }
            try self.output(from: SavedInput(input))
        } else {
            _ = try await Self.query(on: database)
                .set(self.collectInput(withDefaultedValues: database is any SQLDatabase))
                .action(.create)
                .run()
            try self.output(from: SavedInput(self.collectInput()))
        }
    }

    public func update(on database: any Database) async throws {
        try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try await model.handle(event, on: db)
        }.handle(.update, self, on: database)
    }

    private func _update(on database: any Database) async throws {
        precondition(self._$idExists)
        guard self.hasChanges else {
            return
        }
        self.touchTimestamps(.update)
        let input = self.collectInput()
        guard let id = self.id else { throw FluentError.idRequired }
        try await Self.query(on: database)
            .filter(id: id)
            .set(input)
            .update()
        try self.output(from: SavedInput(input))
    }

    public func delete(on database: any Database) async throws {
        try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try await model.handle(event, on: db)
        }.handle(.delete, self, on: database)
    }

    private func _delete(on database: any Database) async throws {
        guard let id = self.id else { throw FluentError.idRequired }
        try await Self.query(on: database)
            .filter(id: id)
            .delete()
        self._$idExists = false
    }

    private func handle(_ event: ModelEvent, on db: any Database) async throws {
        switch event {
        case .create:
            try await self._create(on: db)
        case .delete:
            try await self._delete(on: db)
        case .update:
            try await self._update(on: db)
        }
    }
}

extension Collection where Element: FluentKit.Model, Self: Sendable {
    public func delete(on database: any Database) async throws {
        guard !self.isEmpty else {
            return
        }
        
        precondition(self.allSatisfy { $0._$idExists })

        for model in self {
            try await database.configuration.middleware.chainingTo(Element.self) { _, _, _ in }.delete(model, on: database)
        }
        try await Element.query(on: database)
            .filter(ids: self.map { $0.id! })
            .delete()

        for model in self {
            model._$idExists = false
        }
    }

    public func create(on database: any Database) async throws {
        guard !self.isEmpty else {
            return
        }
        
        precondition(self.allSatisfy { !$0._$idExists })

        for model in self {
            try await database.configuration.middleware.chainingTo(Element.self) { event, model, db in
                if model.anyID is any AnyQueryableProperty {
                    model._$id.generate()
                }
                model.touchTimestamps(.create, .update)
            }.create(model, on: database)
        }
        try await Element.query(on: database)
            .set(self.map { $0.collectInput(withDefaultedValues: database is any SQLDatabase) })
            .create()
        for model in self {
            model._$idExists = true
        }
    }
}

public enum MiddlewareFailureHandler {
    /// Insert objects which middleware did not fail
    case insertSucceeded
    /// If a failure has occurs in a middleware, none of the models are saved and the first failure is returned.
    case failOnFirst
}

// MARK: Private

private struct SavedInput: DatabaseOutput {
    var input: [FieldKey: DatabaseQuery.Value]
    
    init(_ input: [FieldKey: DatabaseQuery.Value]) {
        self.input = input
    }

    func schema(_ schema: String) -> any DatabaseOutput {
        self
    }
    
    func contains(_ key: FieldKey) -> Bool {
        self.input[key] != nil
    }

    func nested(_ key: FieldKey) throws -> any DatabaseOutput {
        guard let data = self.input[key] else {
            throw FluentError.missingField(name: key.description)
        }
        guard case .dictionary(let nested) = data else {
            fatalError("Unexpected input: \(data).")
        }
        return SavedInput(nested)
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        guard let value = self.input[key] else {
            throw FluentError.missingField(name: key.description)
        }
        switch value {
        case .null:
            return true
        default:
            return false
        }
    }
    
    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T : Decodable
    {
        guard let value = self.input[key] else {
            throw FluentError.missingField(name: key.description)
        }
        switch value {
        case .bind(let encodable):
            return encodable as! T
        case .enumCase(let string):
            return string as! T
        default:
            fatalError("Invalid input type: \(value)")
        }
    }

    var description: String {
        self.input.description
    }
}
