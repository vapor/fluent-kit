public protocol DatabaseInput {
    func set(_ value: DatabaseQuery.Value, at key: FieldKey)
}

extension DatabaseInput {
    public func prefixed(by prefix: FieldKey) -> DatabaseInput {
        PrefixedDatabaseInput(prefix: prefix, strategy: .none, base: self)
    }
    
    public func prefixed(by prefix: FieldKey, using stratgey: KeyPrefixingStrategy) -> DatabaseInput {
        PrefixedDatabaseInput(prefix: prefix, strategy: stratgey, base: self)
    }
}

private struct PrefixedDatabaseInput: DatabaseInput {
    let prefix: FieldKey
    let strategy: KeyPrefixingStrategy
    let base: DatabaseInput

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.base.set(value, at: self.strategy.apply(prefix: self.prefix, to: key))
    }
}

