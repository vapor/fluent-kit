import NIOCore

extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self._$idExists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try model.handle(event, on: db)
        }.handle(.create, self, on: database)
    }

    private func _create(on database: Database) -> EventLoopFuture<Void> {
        precondition(!self._$idExists)
        self.touchTimestamps(.create, .update)
        if self.anyID is AnyQueryableProperty {
            self.anyID.generate()
            let promise = database.eventLoop.makePromise(of: DatabaseOutput.self)
            Self.query(on: database)
                .set(self.collectInput())
                .action(.create)
                .run { promise.succeed($0) }
                .cascadeFailure(to: promise)
            return promise.futureResult.flatMapThrowing { output in
                var input = self.collectInput()
                if case .default = self._$id.inputValue {
                    let idKey = Self()._$id.key
                    input[idKey] = try .bind(output.decode(idKey, as: Self.IDValue.self))
                }
                try self.output(from: SavedInput(input))
            }
        } else {
            return Self.query(on: database)
                .set(self.collectInput())
                .action(.create)
                .run()
                .flatMapThrowing {
                    try self.output(from: SavedInput(self.collectInput()))
                }
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try model.handle(event, on: db)
        }.handle(.update, self, on: database)
    }

    private func _update(on database: Database) throws -> EventLoopFuture<Void> {
        precondition(self._$idExists)
        guard self.hasChanges else {
            return database.eventLoop.makeSucceededFuture(())
        }
        self.touchTimestamps(.update)
        let input = self.collectInput()
        guard let id = self.id else { throw FluentError.idRequired }
        return Self.query(on: database)
            .filter(id: id)
            .set(input)
            .update()
            .flatMapThrowing
        {
            try self.output(from: SavedInput(input))
        }
    }

    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        if !force, let timestamp = self.deletedTimestamp {
            timestamp.touch()
            return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
                try model.handle(event, on: db)
            }.handle(.softDelete, self, on: database)
        } else {
            return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
                try model.handle(event, on: db)
            }.handle(.delete(force), self, on: database)
        }
    }

    private func _delete(force: Bool = false, on database: Database) throws -> EventLoopFuture<Void> {
        guard let id = self.id else { throw FluentError.idRequired }
        return Self.query(on: database)
            .filter(id: id)
            .delete(force: force)
            .map
        {
            if force || self.deletedTimestamp == nil {
                self._$idExists = false
            }
        }
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try model.handle(event, on: db)
        }.handle(.restore, self, on: database)
    }

    private func _restore(on database: Database) throws -> EventLoopFuture<Void> {
        guard let timestamp = self.timestamps.filter({ $0.trigger == .delete }).first else {
            fatalError("no delete timestamp on this model")
        }
        timestamp.touch(date: nil)
        precondition(self._$idExists)
        guard let id = self.id else { throw FluentError.idRequired }
        return Self.query(on: database)
            .withDeleted()
            .filter(id: id)
            .set(self.collectInput())
            .action(.update)
            .run()
            .flatMapThrowing
        {
            try self.output(from: SavedInput(self.collectInput()))
            self._$idExists = true
        }
    }

    private func handle(_ event: ModelEvent, on db: Database) throws -> EventLoopFuture<Void> {
        switch event {
        case .create:
            return _create(on: db)
        case .delete(let force):
            return try _delete(force: force, on: db)
        case .restore:
            return try _restore(on: db)
        case .softDelete:
            return try _delete(force: false, on: db)
        case .update:
            return try _update(on: db)
        }
    }
}

extension Collection where Element: FluentKit.Model {
    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        guard !self.isEmpty else {
            return database.eventLoop.makeSucceededFuture(())
        }
        
        precondition(self.allSatisfy { $0._$idExists })

        return EventLoopFuture<Void>.andAllSucceed(self.map { model in
            database.configuration.middleware.chainingTo(Element.self) { event, model, db in
                return db.eventLoop.makeSucceededFuture(())
            }.delete(model, force: force, on: database)
        }, on: database.eventLoop).flatMap {
            Element.query(on: database)
                .filter(ids: self.map { $0.id! })
                .delete(force: force)
        }.map {
            guard force else { return }
            
            for model in self where model.deletedTimestamp == nil {
                model._$idExists = false
            }
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        guard !self.isEmpty else {
            return database.eventLoop.makeSucceededFuture(())
        }
        
        precondition(self.allSatisfy { !$0._$idExists })
        
        return EventLoopFuture<Void>.andAllSucceed(self.enumerated().map { idx, model in
            database.configuration.middleware.chainingTo(Element.self) { event, model, db in
                if model.anyID is AnyQueryableProperty {
                    model._$id.generate()
                }
                model.touchTimestamps(.create, .update)
                return db.eventLoop.makeSucceededFuture(())
            }.create(model, on: database)
        }, on: database.eventLoop).flatMap {
            Element.query(on: database)
                .set(self.map { $0.collectInput() })
                .create()
        }.map {
            for model in self {
                model._$idExists = true
            }
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

    func schema(_ schema: String) -> DatabaseOutput {
        return self
    }
    
    func contains(_ key: FieldKey) -> Bool {
        self.input[key] != nil
    }

    func nested(_ key: FieldKey) throws -> DatabaseOutput {
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
        return self.input.description
    }
}
