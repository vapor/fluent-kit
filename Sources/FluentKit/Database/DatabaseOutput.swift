public struct DatabaseOutput {
    public let database: Database
    public let row: DatabaseRow
    
    public func contains(_ field: FieldKey) -> Bool {
        return self.row.contains(field: field)
    }

    public func decode<T>(_ field: FieldKey, as: T.Type = T.self) throws -> T
        where T: Decodable
    {
        return try self.row.decode(field: field, as: T.self, for: self.database)
    }
}

extension DatabaseOutput {
    func prefixed(by string: String) -> DatabaseOutput {
        .init(
            database: self.database,
            row: self.row.prefixed(by: string)
        )
    }
}

public protocol DatabaseRow: CustomStringConvertible {
    func contains(field: FieldKey) -> Bool
    func decode<T>(
        field: FieldKey,
        as type: T.Type,
        for database: Database
    ) throws -> T
        where T: Decodable
}

extension DatabaseRow {
    public func output(for database: Database) -> DatabaseOutput {
        return .init(database: database, row: self)
    }
}

extension DatabaseRow {
    func prefixed(by string: String) -> DatabaseRow {
        return PrefixingOutput(wrapped: self, prefix: string)
    }
}

private struct PrefixingOutput: DatabaseRow {
    let wrapped: DatabaseRow
    let prefix: String

    var description: String {
        return self.wrapped.description
    }

    func contains(field: FieldKey) -> Bool {
        return self.wrapped.contains(field: .prefixed(self.prefix, field))
    }

    func decode<T>(
        field: FieldKey,
        as type: T.Type,
        for database: Database
    ) throws -> T where T : Decodable {
        return try self.wrapped.decode(field: .prefixed(self.prefix, field), as: T.self, for: database)
    }
}

extension DatabaseRow {
    func cascading(to output: DatabaseRow) -> DatabaseRow {
        return CombinedOutput(first: self, second: output)
    }
}

private struct CombinedOutput: DatabaseRow {
    var first: DatabaseRow
    var second: DatabaseRow

    func contains(field: FieldKey) -> Bool {
        return self.first.contains(field: field) || self.second.contains(field: field)
    }

    func decode<T>(field: FieldKey, as type: T.Type, for database: Database) throws -> T
        where T : Decodable
    {
        if self.first.contains(field: field) {
            return try self.first.decode(field: field, as: T.self, for: database)
        } else if self.second.contains(field: field) {
            return try self.second.decode(field: field, as: T.self, for: database)
        } else {
            throw FluentError.missingField(name: field.description)
        }
    }

    var description: String {
        return self.first.description + " -> " + self.second.description
    }
}

