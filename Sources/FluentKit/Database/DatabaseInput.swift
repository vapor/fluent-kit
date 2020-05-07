public protocol DatabaseInput {
    func set(_ value: DatabaseQuery.Value, at key: FieldKey)
}

extension DatabaseInput {
    public func prefixed(by prefix: FieldKey) -> DatabaseInput {
        PrefixedDatabaseInput(prefix: prefix, base: self)
    }
}

private struct PrefixedDatabaseInput: DatabaseInput {
    let prefix: FieldKey
    let base: DatabaseInput

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.base.set(value, at: .prefix(self.prefix, key))
    }
}

//public struct DatabaseInput {
//    public var values: [FieldKey: DatabaseQuery.Value]
//    public init() {
//        self.values = [:]
//    }
//}
