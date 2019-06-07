extension Row {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        if let timestampable = Model.shared as? _AnyTimestampable {
            timestampable._touchCreated(&self.storage.input)
        }
        precondition(!self.exists)
        if let generatedIDType = Model.ID.self as? AnyGeneratableID.Type {
            self.id = (generatedIDType.anyGenerateID() as! Model.ID)
        }
        return Model.shared.willCreate(self, on: database).flatMap {
            return Model.query(on: database)
                .set(self.storage.input)
                .action(.create)
                .run { created in
                    if Model.ID.self is AnyGeneratableID.Type { } else {
                        self.id = try created.storage.output!.decode(field: "fluentID", as: Model.ID.self)
                    }
                    self.storage.exists = true
            }
        }.flatMap {
            return Model.shared.didCreate(self, on: database)
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        if let timestampable = Model.shared as? _AnyTimestampable {
            timestampable._touchUpdated(&self.storage.input)
        }
        precondition(self.exists)
        return Model.shared.willUpdate(self, on: database).flatMap {
            return Model.query(on: database)
                .filter(\.id == self.id)
                .set(self.storage.input)
                .action(.update)
                .run()
        }.flatMap {
            return Model.shared.didUpdate(self, on: database)
        }
    }

    public func delete(on database: Database) -> EventLoopFuture<Void> {
        if let softDeletable = Model.shared as? _AnySoftDeletable {
            softDeletable._clearDeletedAt(&self.storage.input)
            return Model.shared.willSoftDelete(self, on: database).flatMap {
                return self.update(on: database)
            }.flatMap {
                return Model.shared.didSoftDelete(self, on: database)
            }
        } else {
            return Model.shared.willDelete(self, on: database).flatMap {
                return Model.query(on: database)
                    .filter(\.id == self.id)
                    .action(.delete)
                    .run()
                    .map {
                        self.storage.exists = false
                    }
            }.flatMap {
                return Model.shared.didDelete(self, on: database)
            }
        }
    }
}

extension Row where Model: SoftDeletable {
    public func forceDelete(on database: Database) -> EventLoopFuture<Void> {
        return Model.shared.willDelete(self, on: database).flatMap {
            return Model.query(on: database)
                .withSoftDeleted()
                .filter(\.id == self.id)
                .action(.delete)
                .run()
                .map {
                    self.storage.exists = false
                }
        }.flatMap {
            return Model.shared.didDelete(self, on: database)
        }
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        self.deletedAt = nil
        precondition(self.exists)
        return Model.shared.willRestore(self, on: database).flatMap {
            return Model.query(on: database)
                .withSoftDeleted()
                .filter(\.id == self.id)
                .set(self.storage.input)
                .action(.update)
                .run()
        }.flatMap {
            return Model.shared.didRestore(self, on: database)
        }
    }
}
