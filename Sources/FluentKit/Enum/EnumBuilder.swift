extension Database {
    public func `enum`(_ name: String) -> EnumBuilder {
        .init(database: self, name: name)
    }
}

public final class EnumBuilder {
    let database: Database
    public var `enum`: DatabaseEnum

    init(database: Database, name: String) {
        self.database = database
        self.enum = .init(name: name)
    }

    public func `case`(_ name: String) -> Self {
        self.enum.createCases.append(name)
        return self
    }

    public func deleteCase(_ name: String) -> Self {
        self.enum.deleteCases.append(name)
        return self
    }

    public func create() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.enum.action = .create
        return self.database.execute(enum: self.enum).flatMap {
            self.enum.generateDatatype(on: self.database)
        }
    }

    public func update() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.enum.action = .update
        return self.database.execute(enum: self.enum).flatMap {
            self.enum.generateDatatype(on: self.database)
        }
    }

    public func delete() -> EventLoopFuture<Void> {
        self.enum.action = .update
        return self.database.execute(enum: self.enum)
    }
}
