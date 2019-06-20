public protocol Timestampable: Model, _AnyTimestampable {
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}


public protocol _AnyTimestampable {
    var _createdAtField: Field<Date?> { get }
    var _updatedAtField: Field<Date?> { get }
}

extension Timestampable {
    public var _createdAtField: Field<Date?> {
        guard let createdAt = Mirror(reflecting: self).descendant("$$createdAt") else {
            fatalError("createdAt must be declared using @Field")
        }
        return createdAt as! Field<Date?>
    }

    public var _updatedAtField: Field<Date?> {
        guard let updatedAt = Mirror(reflecting: self).descendant("$$updatedAt") else {
            fatalError("updatedAt must be declared using @Field")
        }
        return updatedAt as! Field<Date?>
    }
}
