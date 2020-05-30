extension DatabaseOutput {
    public func prefixed(by prefix: FieldKey) -> DatabaseOutput {
        PrefixedOutput(prefix: prefix, base: self)
    }
}

private struct PrefixedOutput: DatabaseOutput {
    let prefix: FieldKey
    let base: DatabaseOutput

    func schema(_ schema: String) -> DatabaseOutput {
        PrefixedOutput(prefix: self.prefix, base: self.base.schema(schema))
    }

    func contains(_ key: FieldKey) -> Bool {
        return self.base.contains(self.key(key))
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.base.decodeNil(self.key(key))
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.base.decode(self.key(key))
    }

    func key(_ key: FieldKey) -> FieldKey {
        .prefix(self.prefix, key)
    }

    var description: String {
        self.base.description
    }
}
