struct DatabaseInput {
    var values: [FieldKey: DatabaseQuery.Value]
    init() {
        self.values = [:]
    }
}
