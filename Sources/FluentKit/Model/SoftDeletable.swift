public protocol SoftDeletable: Model, _AnySoftDeletable {
    var deletedAt: Field<Date?> { get }
}

public protocol _AnySoftDeletable {
    var _anyDeletedAtFieldName: String { get }
}

extension SoftDeletable {
    public var _anyDeletedAtFieldName: String {
        return self.deletedAt.name
    }
}

extension QueryBuilder {
    public func withSoftDeleted() -> Self {
        self.includeSoftDeleted = true
        return self
    }
}
