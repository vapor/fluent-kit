public extension SQLRow {
    var fluentOutput: DatabaseOutput {
        return _FluentOutputWrapper(self)
    }
}

private struct _FluentOutputWrapper: DatabaseOutput {
    public let row: SQLRow
    public init(_ row: SQLRow) {
        self.row = row
    }
    
    public var description: String {
        return "\(self.row)"
    }

    func contains(field: String) -> Bool {
        return self.row.contains(column: field)
    }
    
    public func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.row.decode(column: field, as: T.self)
    }
}
