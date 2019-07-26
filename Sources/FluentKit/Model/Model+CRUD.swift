extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self.idField.exists {
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
        precondition(!self.idField.exists)
        if let generatedIDType = Self.ID.self as? AnyGeneratableID.Type {
            self.id = (generatedIDType.anyGenerateID() as! Self.ID)
        }
        return self.willCreate(on: database).flatMap {
            var input = self.input
            return Self.query(on: database)
                .set(input)
                .action(.create)
                .run { output in
                    if Self.ID.self is GeneratableID.Type { } else {
                        let id = try output.decode(field: "fluentID", as: Self.ID.self)
                        input[Self.key(for: \.idField)] = .bind(id)
                    }
                    try self.output(from: SavedInput(input))
                }
        }.flatMap {
            return self.didCreate(on: database)
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        if let timestampable = self as? _AnyTimestampable {
            timestampable._updatedAtField.wrappedValue = Date()
        }
        precondition(self.idField.exists)

        return self.willUpdate(on: database).flatMap {
            let input = self.input
            return Self.query(on: database)
                .filter(\.idField == self.id)
                .set(input)
                .action(.update)
                .run()
                .flatMapThrowing {
                    try self.output(from: SavedInput(input))
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
                    .filter(\.idField == self.id)
                    .action(.delete)
                    .run()
                    .flatMapThrowing {
                        self.idField.exists = false
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
                .filter(\.idField == self.id)
                .action(.delete)
                .run()
                .map {
                    self.idField.exists = false
                }
        }.flatMap {
            return self.didDelete(on: database)
        }
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        self.deletedAt = nil
        precondition(self.idField.exists)
        return self.willRestore(on: database).flatMap {
            return Self.query(on: database)
                .withSoftDeleted()
                .filter(\.idField == self.id)
                .set(self.input)
                .action(.update)
                .run()
                .flatMapThrowing {
                    try self.output(from: SavedInput(self.input))
                    self.idField.exists = true
                }
        }.flatMap {
            return self.didRestore(on: database)
        }
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
            fatalError("not found in saved input: \(field)")
            throw FluentError.missingField(name: field)
        }
    }

    var description: String {
        return self.input.description
    }
}
