import NIOCore
import protocol SQLKit.SQLDatabase

public extension Model {
    static func find(
        _ id: Self.IDValue?,
        on database: any Database
    ) async throws -> Self? {
        guard let id = id else { return nil }
        return try await Self.query(on: database)
            .filter(id: id)
            .first()
    }
    
    // MARK: - CRUD
    func save(on database: any Database) async throws {
        if self._$idExists {
            try await self.update(on: database)
        } else {
            try await self.create(on: database)
        }
    }
    
    func create(on database: any Database) async throws {
        try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try await model.handle(event, on: db)
        }.handle(.create, self, on: database)
    }

    private func _create(on database: any Database) async throws {
        precondition(!self._$idExists)
        self.touchTimestamps(.create, .update)
        if self.anyID is any AnyQueryableProperty {
            self.anyID.generate()
            
            nonisolated(unsafe) var output: (any DatabaseOutput)?
            try await Self.query(on: database)
                .set(self.collectInput(withDefaultedValues: database is any SQLDatabase))
                .action(.create)
                .run { output = $0 }

            var input = self.collectInput()
            if case .default = self._$id.inputValue {
                let idKey = Self()._$id.key
                // In theory, this shouldn't happen, but in case it does in some edge case,
                // better to throw an error than crash with an IUO.
                guard let output else { throw RunQueryError.noDatabaseOutput }
                input[idKey] = try .bind(output.decode(idKey, as: Self.IDValue.self))
            }
            try self.output(from: SavedInput(input))
        } else {
            // non-ID case: run async and then perform the decoding step
            try await Self.query(on: database)
                .set(self.collectInput(withDefaultedValues: database is any SQLDatabase))
                .action(.create)
                .run()
            try self.output(from: SavedInput(self.collectInput()))
        }
    }
    
    func update(on database: any Database) async throws {
        try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try await model.handle(event, on: db)
        }.handle(.update, self, on: database)
    }

    private func _update(on database: any Database) async throws {
        precondition(self._$idExists)
        guard self.hasChanges else { return }
        self.touchTimestamps(.update)
        let input = self.collectInput()
        guard let id = self.id else { throw FluentError.idRequired }
        try await Self.query(on: database)
            .filter(id: id)
            .set(input)
            .update()
        try self.output(from: SavedInput(input))
    }
    
    func delete(force: Bool = false, on database: any Database) async throws {
        if !force, let timestamp = self.deletedTimestamp {
            timestamp.touch()
            try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
                try await model.handle(event, on: db)
            }.handle(.softDelete, self, on: database)
        } else {
            try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
                try await model.handle(event, on: db)
            }.handle(.delete(force), self, on: database)
        }
    }

    private func _delete(force: Bool = false, on database: any Database) async throws {
        guard let id = self.id else { throw FluentError.idRequired }
        try await Self.query(on: database)
            .filter(id: id)
            .delete(force: force)   
        if force || self.deletedTimestamp == nil {
            self._$idExists = false
        }
    }
    
    func restore(on database: any Database) async throws {
        try await database.configuration.middleware.chainingTo(Self.self) { event, model, db in
            try await model.handle(event, on: db)
        }.handle(.restore, self, on: database)
    }

    private func _restore(on database: any Database) async throws {
        guard let timestamp = self.timestamps.filter({ $0.trigger == .delete }).first else {
            fatalError("no delete timestamp on this model")
        }
        timestamp.touch(date: nil)
        precondition(self._$idExists)
        guard let id = self.id else { throw FluentError.idRequired }
        let _: Void = try await Self.query(on: database)
            .withDeleted()
            .filter(id: id)
            .set(self.collectInput())
            .action(.update)
            .run()

        try self.output(from: SavedInput(self.collectInput()))
        self._$idExists = true
    }

    func handle(_ event: ModelEvent, on db: any Database) async throws -> Void {
        switch event {
        case .create:
            try await _create(on: db)
        case .delete(let force):
            try await _delete(force: force, on: db)
        case .restore:
            try await _restore(on: db)
        case .softDelete:
            try await _delete(force: false, on: db)
        case .update:
            try await _update(on: db)
        }
    }
}

public extension Collection where Element: FluentKit.Model, Self: Sendable {
    func delete(force: Bool = false, on database: any Database) async throws {
        guard !self.isEmpty else { return }
        
        precondition(self.allSatisfy { $0._$idExists })
        for model in self {
            try await database.configuration.middleware.chainingTo(Element.self) { event, model, db in
                return
            }.delete(model, force: force, on: database)
        }

        try await Element.query(on: database)
            .filter(ids: self.map { $0.id! })
            .delete(force: force)

        guard force else { return }
        for model in self where model.deletedTimestamp == nil {
            model._$idExists = false
        }
    }
    
    func create(on database: any Database) async throws {
        guard !self.isEmpty else { return }
        
        precondition(self.allSatisfy { !$0._$idExists })

        try await withThrowingTaskGroup(of: Void.self) { group in
            for model in self {
                group.addTask {
                    try await database.configuration.middleware.chainingTo(Element.self) { event, model, db in
                        if model.anyID is any AnyQueryableProperty {
                            model._$id.generate()
                        }
                        model.touchTimestamps(.create, .update)
                    }.create(model, on: database)
                }
            }
            try await group.waitForAll()
        }

        try await Element.query(on: database)
            .set(self.map { $0.collectInput(withDefaultedValues: database is any SQLDatabase) })
            .create()

        for model in self {
            model._$idExists = true
        }
    }
}
