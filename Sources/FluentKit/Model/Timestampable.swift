public protocol Timestampable: Model, _AnyTimestampable {
    var createdAt: Field<Date?> { get }
    var updatedAt: Field<Date?> { get }
}


public protocol _AnyTimestampable {
    func _touchCreatedAt(from input: inout [String: DatabaseQuery.Value])
    func _touchUpdatedAt(from input: inout [String: DatabaseQuery.Value])
}

extension Timestampable {
    public func _touchCreatedAt(from input: inout [String: DatabaseQuery.Value]) {
        input[self.createdAt.name] = .bind(Date())
    }
    public func _touchUpdatedAt(from input: inout [String: DatabaseQuery.Value]) {
        input[self.updatedAt.name] = .bind(Date())
    }
}
