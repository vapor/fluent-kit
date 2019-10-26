extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self._$id.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }
    
    public func create(on database: Database) -> EventLoopFuture<Void> {
        return database.context.middleware.chainingTo { event, model, db in
            self._create(on: db)
        }.handle(event: .create, model: self, on: database)
    }
    
    private func _create(on database: Database) -> EventLoopFuture<Void> {
        self.touchTimestamps(.create, .update)
        precondition(!self._$id.exists)
        self._$id.generate()
        let promise = database.eventLoop.makePromise(of: DatabaseOutput.self)
        Self.query(on: database)
            .set(self.input)
            .action(.create)
            .run { promise.succeed($0) }
            .cascadeFailure(to: promise)
        return promise.futureResult.flatMapThrowing { output in
            var input = self.input
            if self._$id.generator == .database {
                let id = try output.decode("fluentID", as: Self.IDValue.self)
                input[Self.key(for: \._$id)] = .bind(id)
            }
            try self.output(from: SavedInput(input).output(for: database))
        }
    }
    
    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.context.middleware.chainingTo { event, model, db in
            self._update(on: db)
        }.handle(event: .update, model: self, on: database)
    }
    
    private func _update(on database: Database) -> EventLoopFuture<Void> {
        self.touchTimestamps(.update)
        precondition(self._$id.exists)
        let input = self.input
        return Self.query(on: database)
            .filter(\._$id == self.id!)
            .set(input)
            .action(.update)
            .run()
            .flatMapThrowing {
                try self.output(from: SavedInput(input).output(for: database))
        }
    }
    
    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        if !force, let timestamp = self.timestamps.filter({ $0.1.trigger == .delete }).first {
            timestamp.1.touch()
            return database.context.middleware.chainingTo { event, model, db in
                self._update(on: db)
            }.handle(event: .softDelete, model: self, on: database)
        } else {
            return database.context.middleware.chainingTo { event, model, db in
                self._delete(force: force, on: db)
            }.handle(event: .delete, model: self, on: database)
        }
    }
    
    private func _delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        let query = Self.query(on: database)
        if force {
            _ = query.withDeleted()
        }
        return query
            .filter(\._$id == self.id!)
            .action(.delete)
            .run()
            .map {
                self._$id.exists = false
        }
    }
    
    public func restore(on database: Database) -> EventLoopFuture<Void> {
        return database.context.middleware.chainingTo { event, model, db in
            self._restore(on: db)
        }.handle(event: .restore, model: self, on: database)
    }
    
    private func _restore(on database: Database) -> EventLoopFuture<Void> {
        guard let timestamp = self.timestamps.filter({ $0.1.trigger == .delete }).first else {
            fatalError("no delete timestamp on this model")
        }
        timestamp.1.touch(date: nil)
        precondition(self._$id.exists)
        return Self.query(on: database)
            .withDeleted()
            .filter(\._$id == self.id!)
            .set(self.input)
            .action(.update)
            .run()
            .flatMapThrowing {
                try self.output(from: SavedInput(self.input).output(for: database))
                self._$id.exists = true
        }
    }
}

extension Array where Element: FluentKit.Model {
    public func create(on database: Database) -> EventLoopFuture<Void> {
        let builder = Element.query(on: database)
        self.forEach { model in
            precondition(!model._$id.exists)
        }
        
        self.forEach {
            $0._$id.generate()
            $0.touchTimestamps(.create)
            $0.touchTimestamps(.update)
        }
        builder.set(self.map { $0.input })
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { created in
            let next = it.next()!
            next._$id.exists = true
        }
        
    }
}

// MARK: Private
private struct SavedInput: DatabaseRow {
    var input: [String: DatabaseQuery.Value]
    
    init(_ input: [String: DatabaseQuery.Value]) {
        self.input = input
    }
    
    func contains(field: String) -> Bool {
        return self.input[field] != nil
    }
    
    func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T where T : Decodable {
        if let value = self.input[field] {
            // not in output, get from saved input
            switch value {
            case .bind(let encodable):
                return encodable as! T
            default:
                fatalError("Invalid input type: \(value)")
            }
        } else {
            throw FluentError.missingField(name: field)
        }
    }
    
    var description: String {
        return self.input.description
    }
}
