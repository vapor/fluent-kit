extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self._$id.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }

    public func create(on database: Database) -> EventLoopFuture<Void> {
        self.touchTimestamps(.create, .update)
        precondition(!self._$id.exists)
        return self.willCreate(on: database).flatMap {
            self._$id.generate()
            return Self.query(on: database)
                .set(self.input)
                .action(.create)
                .run { output in
                    var input = self.input
                    if output.contains(field: "fluentID") {
                        let id = try output.decode(field: "fluentID", as: Self.IDValue.self)
                        input[Self.key(for: \._$id)] = .bind(id)
                    }
                    try self.output(from: SavedInput(input))
                }
        }.flatMap {
            return self.didCreate(on: database)
        }
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        self.touchTimestamps(.update)
        precondition(self._$id.exists)

        return self.willUpdate(on: database).flatMap {
            let input = self.input
            return Self.query(on: database)
                .filter(\._$id == self.id!)
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

    public func delete(force: Bool = false, on database: Database) -> EventLoopFuture<Void> {
        if !force, let timestamp = self.timestamps.filter({ $0.1.trigger == .delete }).first {
            timestamp.1.touch()
            return self.willSoftDelete(on: database).flatMap {
                return self.update(on: database)
            }.flatMap {
                return self.didSoftDelete(on: database)
            }
        } else {
            return self.willDelete(on: database).flatMap {
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
            }.flatMap {
                return self.didDelete(on: database)
            }
        }
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        guard let timestamp = self.timestamps.filter({ $0.1.trigger == .delete }).first else {
            fatalError("no delete timestamp on this model")
        }
        timestamp.1.touch(date: nil)
        precondition(self._$id.exists)
        return self.willRestore(on: database).flatMap {
            return Self.query(on: database)
                .withDeleted()
                .filter(\._$id == self.id!)
                .set(self.input)
                .action(.update)
                .run()
                .flatMapThrowing {
                    try self.output(from: SavedInput(self.input))
                    self._$id.exists = true
                }
        }.flatMap {
            return self.didRestore(on: database)
        }
    }
}

extension Array where Element: FluentKit.Model {
    public func create(on database: Database) -> EventLoopFuture<Void> {
        let builder = Element.query(on: database)
        self.forEach { model in
            precondition(!model._$id.exists)
        }
        return EventLoopFuture<Void>.andAllSucceed(
            self.map { $0.willCreate(on: database) },
            on: database.eventLoop
        ).flatMap {
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
        }.flatMap {
            return EventLoopFuture<Void>.andAllSucceed(
                self.map { $0.didCreate(on: database) },
                on: database.eventLoop
            )
        }
    }
}


// MARK: Private

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
