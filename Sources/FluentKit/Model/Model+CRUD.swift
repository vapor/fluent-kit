extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self._$id.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            model.handle(event, on: db)
        }.handle(.create, self, on: database)
    }

    private func _create(on database: Database) -> EventLoopFuture<Void> {
        precondition(!self._$id.exists)
        self.touchTimestamps(.create, .update)
        self._$id.generate()
        let promise = database.eventLoop.makePromise(of: DatabaseOutput.self)
        Self.query(on: database)
            .set(self.collectInput())
            .action(.create)
            .run { promise.succeed($0) }
            .cascadeFailure(to: promise)
        return promise.futureResult.flatMapThrowing { output in
            var input = self.collectInput()
            if self._$id.generator == .database {
                let idKey = Self()._$id.key
                input[idKey] = try .bind(output.decode(idKey, as: Self.IDValue.self))
            }
            try self.output(from: SavedInput(input))
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            model.handle(event, on: db)
        }.handle(.update, self, on: database)
    }

    private func _update(on database: Database) -> EventLoopFuture<Void> {
        precondition(self._$id.exists)
        guard self.hasChanges else {
            return database.eventLoop.makeSucceededFuture(())
        }
        self.touchTimestamps(.update)
        let input = self.collectInput()
        return Self.query(on: database)
            .filter(\._$id == self.id!)
            .set(input)
            .action(.update)
            .run()
            .flatMapThrowing
        {
            try self.output(from: SavedInput(input))
        }
    }

    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        if !force, let timestamp = self.deletedTimestamp {
            timestamp.touch()
            return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
                model.handle(event, on: db)
            }.handle(.softDelete, self, on: database)
        } else {
            return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
                model.handle(event, on: db)
            }.handle(.delete(force), self, on: database)
        }
    }

    private func _delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        let query = Self.query(on: database)
        if force {
            _ = query.withDeleted()
        }
        
        query.shouldForceDelete = force
        
        return query
            .filter(\._$id == self.id!)
            .action(.delete)
            .run()
            .map
        {
            if force, self.deletedTimestamp == nil {
                self._$id.exists = false
            }
        }
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            model.handle(event, on: db)
        }.handle(.restore, self, on: database)
    }

    private func _restore(on database: Database) -> EventLoopFuture<Void> {
        guard let timestamp = self.timestamps.filter({ $0.trigger == .delete }).first else {
            fatalError("no delete timestamp on this model")
        }
        timestamp.touch(date: nil)
        precondition(self._$id.exists)
        return Self.query(on: database)
            .withDeleted()
            .filter(\._$id == self.id!)
            .set(self.collectInput())
            .action(.update)
            .run()
            .flatMapThrowing
        {
            try self.output(from: SavedInput(self.collectInput()))
            self._$id.exists = true
        }
    }

    private func handle(_ event: ModelEvent, on db: Database) -> EventLoopFuture<Void> {
        switch event {
        case .create:
            return _create(on: db)
        case .delete(let force):
            return _delete(force: force, on: db)
        case .restore:
            return _restore(on: db)
        case .softDelete:
            return _delete(force: false, on: db)
        case .update:
            return _update(on: db)
        }
    }
}

extension Collection where Element: FluentKit.Model {
    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        guard self.count > 0 else {
            // Is it valid to try to create zero models? For now we call it
            // successful without doing anything.
            return database.eventLoop.makeSucceededFuture(())
        }

        let query = Element.query(on: database)
        if force {
            _ = query.withDeleted()
        }
        query.shouldForceDelete = force

        return query
            .filter(\._$id ~~ self.map { $0.id! })
            .action(.delete)
            .run()
            .map
        {
            if force {
                self.forEach {
                    if $0.deletedTimestamp == nil {
                        $0._$id.exists = false
                    }
                }
            }
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        guard self.count > 0 else {
            // Is it valid to try to create zero models? For now we call it
            // successful without doing anything.
            return database.eventLoop.makeSucceededFuture(())
        }

        let builder = Element.query(on: database)
        self.forEach { model in
            precondition(!model._$id.exists)
        }

        self.forEach {
            $0._$id.generate()
            $0.touchTimestamps(.create, .update)
        }
        builder.set(self.map { $0.collectInput() })
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { _ in
            let next = it.next()!
            next._$id.exists = true
        }

    }
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
