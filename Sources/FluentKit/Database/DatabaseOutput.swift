public protocol DatabaseOutput: CustomStringConvertible {
    func schema(_ schema: String) -> DatabaseOutput
    func contains(_ path: [FieldKey]) -> Bool
    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T: Decodable
}

extension DatabaseOutput {
    public func contains(_ path: FieldKey...) -> Bool {
        self.contains(path)
    }
    
    public func decode<T>(_ path: [FieldKey]) throws -> T
        where T: Decodable
    {
        try self.decode(path, as: T.self)
    }

    public func decode<T>(_ path: FieldKey..., as type: T.Type = T.self) throws -> T
        where T: Decodable
    {
        try self.decode(path, as: T.self)
    }
}

extension DatabaseOutput {
    func nested(_ key: FieldKey) -> DatabaseOutput {
        return NestedOutput(wrapped: self, prefix: key)
    }
}

private struct NestedOutput: DatabaseOutput {
    let wrapped: DatabaseOutput
    let prefix: FieldKey

    var description: String {
        self.wrapped.description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        self.wrapped.schema(schema)
    }

    func contains(_ path: [FieldKey]) -> Bool {
        self.wrapped.contains([self.prefix] + path)
    }

    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T : Decodable
    {
        try self.wrapped.decode([self.prefix] + path)
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

    func contains(_ path: [FieldKey]) -> Bool {
        self.first.contains(path) || self.second.contains(path)
    }

    func schema(_ schema: String) -> DatabaseOutput {
        CombinedOutput(
            first: self.first.schema(schema),
            second: self.second.schema(schema)
        )
    }

    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T: Decodable
    {
        if self.first.contains(path) {
            return try self.first.decode(path)
        } else if self.second.contains(path) {
            return try self.second.decode(path)
        } else {
            throw FluentError.missingField(name: path.description)
        }
    }

    var description: String {
        return self.first.description + " -> " + self.second.description
    }
}

