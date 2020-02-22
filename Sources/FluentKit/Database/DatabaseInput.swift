public struct DatabaseInput {
    public var values: [FieldKey: DatabaseQuery.Value]
    public init() {
        self.values = [:]
    }
}
