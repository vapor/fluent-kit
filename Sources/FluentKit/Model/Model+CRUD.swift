extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self._$id.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, models, db in
            Self.handle(event, models, on: database)
        }.handle(.create, [self], on: database)
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, models, db in
            Self.handle(event, models, on: database)
        }.handle(.update, [self], on: database)
    }

    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        database.configuration.middleware.chainingTo(Self.self) { event, models, db in
            Self.handle(event, models, on: database)
        }.handle(.delete(force), [self], on: database)
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Self.self) { event, models, db in
            Self.handle(event, models, on: database)
        }.handle(.restore, [self], on: database)
    }
}

extension Collection where
    Element: FluentKit.Model
{
    public func create(on database: Database) -> EventLoopFuture<Void> {
        database.configuration.middleware.chainingTo(Element.self) { event, models, db in
            Element.handle(event, models, on: database)
        }.handle(.create, .init(self), on: database)
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Element.self) { event, models, db in
            Element.handle(event, models, on: database)
        }.handle(.update, .init(self), on: database)
    }

    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        database.configuration.middleware.chainingTo(Element.self) { event, models, db in
            Element.handle(event, models, on: database)
        }.handle(.delete(force), .init(self), on: database)
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        return database.configuration.middleware.chainingTo(Element.self) { event, models, db in
            Element.handle(event, models, on: database)
        }.handle(.restore, .init(self), on: database)
    }
}

// logic

extension Model {
    static func handle(
        _ event: ModelEvent,
        _ models: [Self],
        on database: Database
    ) -> EventLoopFuture<Void> {
        switch event {
        case .create:
            return self.create(models, on: database)
        case .delete(let force):
            return self.delete(models, force: force, on: database)
        case .restore:
            return self.restore(models, on: database)
        case .softDelete:
            return self.delete(models, force: false, on: database)
        case .update:
            return self.update(models, on: database)
        }
    }

    private static func create(_ models: [Self], on database: Database) -> EventLoopFuture<Void> {
        guard models.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        // Generate identifiers and timestamps.
        models.forEach { model in
            model.touchTimestamps(.create, .update)
            model._$id.generate()
        }

        return Self.query(on: database)
            .set(models.map { $0.collectInput() })
            .action(.create)
            .run { output in
                // Autoincrement hack.
                //
                // When saving to databases with autoincrement ids, one row will be output
                // with the autoincrement value.
                //
                // TODO: Cleanup / formalize.
                do {
                    if case .default = models[0]._$id.inputValue {
                        var input = models[0].collectInput()
                        let idKey = Self()._$id.key
                        input[idKey] = try .bind(output.decode(idKey, as: Self.IDValue.self))
                        try models[0].output(from: SavedInput(input))
                    }
                } catch {
                    database.logger.error("Failed to decode autoincrement: \(error)")
                }
            }
            .flatMapThrowing {
                // Notify all properties of save.
                for model in models {
                    try model.output(from: SavedInput(model.collectInput()))
                }
            }
    }

    private static func update(_ models: [Self], on database: Database) -> EventLoopFuture<Void> {
        // Filter out models that don't need to save.
        let models = models.filter { $0.hasChanges }
        guard models.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        return .andAllSucceed(models.map { model in
            do {
                model.touchTimestamps(.update)
                let input = model.collectInput()
                return try Self.query(on: database)
                    .filter(\._$id == model.requireID())
                    .set(input)
                    .update()
                    .flatMapThrowing
                {
                    try model.output(from: SavedInput(input))
                }
            } catch {
                return database.eventLoop.makeFailedFuture(error)
            }
        }, on: database.eventLoop)
    }

    private static func delete(_ models: [Self], force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        guard models.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        let builder = Self.query(on: database)
        do {
            // Filter ids.
            switch models.count {
            case 1:
                try builder.filter(\._$id == models[0].requireID())
            default:
                try builder.filter(\._$id ~~ models.map { try $0.requireID() })
            }
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }

        return builder.delete(force: force)
            .map
        {
            models.forEach { model in
                if force || model.deletedTimestamp == nil {
                    model._$id.exists = false
                }
            }
        }
    }

    private static func restore(_ models: [Self], on database: Database) -> EventLoopFuture<Void> {
        guard models.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        let builder = Self.query(on: database)
            .withDeleted()
        do {
            // Filter ids.
            switch models.count {
            case 1:
                try builder.filter(\._$id == models[0].requireID())
            default:
                try builder.filter(\._$id ~~ models.map { try $0.requireID() })
            }

            // Get on delete timestamp property.
            guard let timestamp = models[0].timestamps.filter({ $0.trigger == .delete }).first else {
                throw FluentError.missingInput
            }
            let input: [FieldKey: DatabaseQuery.Value] = [
                timestamp.key: .null
            ]
            builder.set(input)

            // Run update.
            return builder
                .action(.update)
                .run()
                .flatMapThrowing
            {
                try models.forEach { model in
                    try model.output(from: SavedInput(input))
                    model._$id.exists = true
                }
            }
        } catch {
            return database.eventLoop.makeFailedFuture(error)
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
