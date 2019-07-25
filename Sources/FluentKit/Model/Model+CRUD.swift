extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        if let timestampable = self as? _AnyTimestampable {
            let date = Date()
            timestampable._createdAtField.wrappedValue = date
            timestampable._updatedAtField.wrappedValue = date
        }
        precondition(!self.exists)
        if let generatedIDType = Self.ID.self as? AnyGeneratableID.Type {
            self.id = (generatedIDType.anyGenerateID() as! Self.ID)
        }
        return self.willCreate(on: database).flatMap {
            return Self.query(on: database)
                .set(self.input)
                .action(.create)
                ._run { storage in
                    if Self.ID.self is AnyGeneratableID.Type { } else {
                        // set id if not generated
                        self.idField.clearInput()
                        try self.idField.setOutput(from: storage)
                    }
                }
        }.flatMap {
            return self.didCreate(on: database)
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        if let timestampable = self as? _AnyTimestampable {
            timestampable._updatedAtField.wrappedValue = Date()
        }
        precondition(self.exists)
        return self.willUpdate(on: database).flatMap {
            return Self.query(on: database)
                .filter(self.idField.name, .equal, self.id)
                .set(self.input)
                .action(.update)
                .run()
        }.flatMap {
            return self.didUpdate(on: database)
        }
    }

    public func delete(on database: Database) -> EventLoopFuture<Void> {
        if let softDeletable = self as? _AnySoftDeletable {
            softDeletable._deletedAtField.wrappedValue = Date()
            return self.willSoftDelete(on: database).flatMap {
                return self.update(on: database)
            }.flatMap {
                return self.didSoftDelete(on: database)
            }
        } else {
            return self.willDelete(on: database).flatMap {
                return Self.query(on: database)
                    .filter(self.idField.name, .equal, self.id)
                    .action(.delete)
                    .run()
                    .map {
                        self.storage!.exists = false
                    }
            }.flatMap {
                return self.didDelete(on: database)
            }
        }
    }
}

extension Model where Self: SoftDeletable {
    public func forceDelete(on database: Database) -> EventLoopFuture<Void> {
        return self.willDelete(on: database).flatMap {
            return Self.query(on: database)
                .withSoftDeleted()
                .filter(self.idField.name, .equal, self.id)
                .action(.delete)
                .run()
                .map {
                    self.storage!.exists = false
                }
        }.flatMap {
            return self.didDelete(on: database)
        }
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        self.deletedAt = nil
        precondition(self.exists)
        return self.willRestore(on: database).flatMap {
            return Self.query(on: database)
                .withSoftDeleted()
                .filter(self.idField.name, .equal, self.id)
                .set(self.input)
                .action(.update)
                .run()
        }.flatMap {
            return self.didRestore(on: database)
        }
    }
}
