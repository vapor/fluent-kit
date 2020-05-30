extension DatabaseOutput {
    public func cascading(to output: DatabaseOutput) -> DatabaseOutput {
        return CombinedOutput(first: self, second: output)
    }
}

private struct CombinedOutput: DatabaseOutput {
    var first: DatabaseOutput
    var second: DatabaseOutput

    func schema(_ schema: String) -> DatabaseOutput {
        CombinedOutput(
            first: self.first.schema(schema),
            second: self.second.schema(schema)
        )
    }

    func contains(_ key: FieldKey) -> Bool {
        self.first.contains(key) || self.second.contains(key)
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        if self.first.contains(key) {
            return try self.first.decodeNil(key)
        } else if self.second.contains(key) {
            return try self.second.decodeNil(key)
        } else {
            throw FluentError.missingField(name: key.description)
        }
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        if self.first.contains(key) {
            return try self.first.decode(key)
        } else if self.second.contains(key) {
            return try self.second.decode(key)
        } else {
            throw FluentError.missingField(name: key.description)
        }
    }

    var description: String {
        return self.first.description + " -> " + self.second.description
    }
}
