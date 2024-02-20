public protocol DatabaseOutput: CustomStringConvertible {
    func schema(_ schema: String) -> DatabaseOutput
    func contains(_ key: FieldKey) -> Bool
    func decodeNil(_ key: FieldKey) throws -> Bool
    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
}

extension DatabaseOutput {
    public func decode<T>(_ key: FieldKey) throws -> T
        where T: Decodable
    {
        try self.decode(key, as: T.self)
    }
    
    public func qualifiedSchema(space: String?, _ schema: String) -> DatabaseOutput {
        self.schema([space, schema].compactMap({ $0 }).joined(separator: "_"))
    }
}

extension DatabaseOutput {
    public func prefixed(by prefix: FieldKey) -> DatabaseOutput {
        PrefixedDatabaseOutput(prefix: prefix, strategy: .none, base: self)
    }
    
    public func prefixed(by prefix: FieldKey, using stratgey: KeyPrefixingStrategy) -> DatabaseOutput {
        PrefixedDatabaseOutput(prefix: prefix, strategy: stratgey, base: self)
    }

    public func cascading(to output: DatabaseOutput) -> DatabaseOutput {
        return CombinedOutput(first: self, second: output)
    }
}

private struct CombinedOutput: DatabaseOutput {
    let first: DatabaseOutput, second: DatabaseOutput

    func schema(_ schema: String) -> DatabaseOutput {
        CombinedOutput(first: self.first.schema(schema), second: self.second.schema(schema))
    }

    func contains(_ key: FieldKey) -> Bool {
        self.first.contains(key) || self.second.contains(key)
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.first.contains(key) ? self.first.decodeNil(key) : self.second.decodeNil(key)
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T where T: Decodable {
        try self.first.contains(key) ? self.first.decode(key, as: T.self) : self.second.decode(key, as: T.self)
    }

    var description: String {
        self.first.description + " -> " + self.second.description
    }
}

private struct PrefixedDatabaseOutput: DatabaseOutput {
    let prefix: FieldKey, strategy: KeyPrefixingStrategy
    let base: DatabaseOutput
    
    func schema(_ schema: String) -> DatabaseOutput {
        PrefixedDatabaseOutput(prefix: self.prefix, strategy: self.strategy, base: self.base.schema(schema))
    }
    
    func contains(_ key: FieldKey) -> Bool {
        self.base.contains(self.strategy.apply(prefix: self.prefix, to: key))
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.base.decodeNil(self.strategy.apply(prefix: self.prefix, to: key))
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T where T : Decodable {
        try self.base.decode(self.strategy.apply(prefix: self.prefix, to: key), as: T.self)
    }

    var description: String {
        "Prefix(\(self.prefix) by \(self.strategy), of: \(self.base.description))"
    }
}

