public protocol DatabaseOutput: CustomStringConvertible {
    func schema(_ schema: String) -> DatabaseOutput
    func contains(_ field: FieldKey) -> Bool
    func decode<T>(_ field: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
}

extension DatabaseOutput {
    func decode<T>(_ field: FieldKey) throws -> T
        where T: Decodable
    {
        try self.decode(field, as: T.self)
    }
}

extension DatabaseOutput {
    func prefixed(by string: String) -> DatabaseOutput {
        return PrefixingOutput(wrapped: self, prefix: string)
    }
}

private struct PrefixingOutput: DatabaseOutput {
    let wrapped: DatabaseOutput
    let prefix: String

    var description: String {
        self.wrapped.description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        self.wrapped.schema(schema)
    }

    func contains(_ field: FieldKey) -> Bool {
        self.wrapped.contains(.prefixed(self.prefix, field))
    }

    func decode<T>(_ field: FieldKey, as type: T.Type) throws -> T
        where T : Decodable
    {
        try self.wrapped.decode(.prefixed(self.prefix, field))
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

    func contains(_ field: FieldKey) -> Bool {
        self.first.contains(field) || self.second.contains(field)
    }

    func schema(_ schema: String) -> DatabaseOutput {
        CombinedOutput(
            first: self.first.schema(schema),
            second: self.second.schema(schema)
        )
    }

    func decode<T>(_ field: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        if self.first.contains(field) {
            return try self.first.decode(field)
        } else if self.second.contains(field) {
            return try self.second.decode(field)
        } else {
            throw FluentError.missingField(name: field.description)
        }
    }

    var description: String {
        return self.first.description + " -> " + self.second.description
    }
}

