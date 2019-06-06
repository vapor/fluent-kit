extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
//        if let timestampable = Model.shared as? _AnyTimestampable {
//            timestampable._touchCreated(&self.storage.input)
//        }
        precondition(!self.exists)
        return self.willCreate(on: database).flatMap {
            return Self.query(on: database)
                .set(self.input)
                .action(.create)
                .run { created in
                    self.id = try created.storage!.output!.decode(field: "fluentID", as: Self.ID.self)
                    self.load(storage: DefaultStorage(output: nil, eagerLoads: [:], exists: true))
                }
        }.flatMap {
            return self.didCreate(on: database)
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
//        if let timestampable = Model.shared as? _AnyTimestampable {
//            timestampable._touchUpdated(&self.storage.input)
//        }
        precondition(self.exists)
        return self.willUpdate(on: database).flatMap {
            return Self.query(on: database)
                .filter(\.id == self.id)
                .set(self.input)
                .action(.update)
                .run()
        }.flatMap {
            return self.didUpdate(on: database)
        }
    }

    public func delete(on database: Database) -> EventLoopFuture<Void> {
//        if let softDeletable = Model.shared as? _AnySoftDeletable {
//            softDeletable._clearDeletedAt(&self.storage.input)
//            return Model.shared.willSoftDelete(self, on: database).flatMap {
//                return self.update(on: database)
//            }.flatMap {
//                return Model.shared.didSoftDelete(self, on: database)
//            }
//        } else {
            return self.willDelete(on: database).flatMap {
                return Self.query(on: database)
                    .filter(\.id == self.id)
                    .action(.delete)
                    .run()
                    .map {
                        self.storage!.exists = false
                    }
            }.flatMap {
                return self.didDelete(on: database)
            }
//        }
    }
}

#warning("TODO: soft-delete")

//extension Row where Model: SoftDeletable {
//    public func forceDelete(on database: Database) -> EventLoopFuture<Void> {
//        return Model.shared.willDelete(self, on: database).flatMap {
//            return Model.query(on: database)
//                .withSoftDeleted()
//                .filter(\.id == self.id)
//                .action(.delete)
//                .run()
//                .map {
//                    self.storage.exists = false
//                }
//        }.flatMap {
//            return Model.shared.didDelete(self, on: database)
//        }
//    }
//
//    public func restore(on database: Database) -> EventLoopFuture<Void> {
//        self.deletedAt = nil
//        precondition(self.exists)
//        return Model.shared.willRestore(self, on: database).flatMap {
//            return Model.query(on: database)
//                .withSoftDeleted()
//                .filter(\.id == self.id)
//                .set(self.storage.input)
//                .action(.update)
//                .run()
//        }.flatMap {
//            return Model.shared.didRestore(self, on: database)
//        }
//    }
//}
