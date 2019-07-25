extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self.storage.exists {
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
        precondition(!self.storage.exists)
        if let generatedIDType = Self.ID.self as? AnyGeneratableID.Type {
            self.id = (generatedIDType.anyGenerateID() as! Self.ID)
        }
        return self.willCreate(on: database).flatMap {
            var output: DatabaseOutput?
            return Self.query(on: database)
                .set(self.storage.input)
                .action(.create)
                .run { output = $0 }
                .map {
                    self.storage.output = output!
                        .cascading(to: SavedInput(self.storage.input))
                    self.storage.input = [:]
                    self.storage.exists = true
                }
        }.flatMap {
            return self.didCreate(on: database)
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        if let timestampable = self as? _AnyTimestampable {
            timestampable._updatedAtField.wrappedValue = Date()
        }
        precondition(self.storage.exists)

        return self.willUpdate(on: database).flatMap {
            return Self.query(on: database)
                .filter(self.idField.name, .equal, self.id)
                .set(self.storage.input)
                .action(.update)
                .run()
                .map {
                    self.storage.output = SavedInput(self.storage.input)
                        .cascading(to: self.storage.output!)
                    self.storage.input = [:]
                    self.storage.exists = true
                }
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
                        self.storage.exists = false
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
                    self.storage.exists = false
                }
        }.flatMap {
            return self.didDelete(on: database)
        }
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        self.deletedAt = nil
        precondition(self.storage.exists)
        return self.willRestore(on: database).flatMap {
            return Self.query(on: database)
                .withSoftDeleted()
                .filter(self.idField.name, .equal, self.id)
                .set(self.storage.input)
                .action(.update)
                .run()
                .map {
                    self.storage.output = SavedInput(self.storage.input)
                        .cascading(to: self.storage.output!)
                    self.storage.input = [:]
                    self.storage.exists = true
                }
        }.flatMap {
            return self.didRestore(on: database)
        }
    }
}

extension DatabaseOutput {
    func cascading(to output: DatabaseOutput) -> DatabaseOutput {
        return CombinedOutput(first: self, second: output)
    }
}
private struct CombinedOutput: DatabaseOutput {
    var first: DatabaseOutput
    var second: DatabaseOutput

    func contains(field: String) -> Bool {
        return self.first.contains(field: field) || self.second.contains(field: field)
    }

    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        if self.first.contains(field: field) {
            return try self.first.decode(field: field, as: T.self)
        } else if self.second.contains(field: field) {
            return try self.second.decode(field: field, as: T.self)
        } else {
            throw FluentError.missingField(name: field)
        }
    }

    var description: String {
        return self.first.description + " -> " + self.second.description
    }
}

private struct SavedInput: DatabaseOutput {
    var input: [String: DatabaseQuery.Value]

    init(_ input: [String: DatabaseQuery.Value]) {
        self.input = input
    }

    func contains(field: String) -> Bool {
        return self.input[field] != nil
    }

    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
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
