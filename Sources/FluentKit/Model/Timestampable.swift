extension AnyModel {
    var timestamps: [(String, Timestamp)] {
        return self.properties.compactMap { (label, property) in
            guard let field = property as? Timestamp else {
                return nil
            }
            return (label, field)
        }
    }
    func touchTimestamps(_ triggers: Timestamp.Trigger...) {
        return self.touchTimestamps(triggers)
    }

    private func touchTimestamps(_ triggers: [Timestamp.Trigger]) {
        let date = Date()
        self.timestamps.forEach { (label, timestamp) in
            if triggers.contains(timestamp.trigger) {
                timestamp.touch(date: date)
            }
        }
    }

    var deletedTimestamp: Timestamp? {
        return self.timestamps.filter({ $0.1.trigger == .delete }).first?.1
    }

    func excludeDeleted(from query: inout DatabaseQuery) {
        guard let timestamp = self.deletedTimestamp else {
            return
        }

        let deletedAtField = DatabaseQuery.Field.field(
            path: [timestamp.key],
            schema: Self.schema,
            alias: nil
        )
        let isNull = DatabaseQuery.Filter.basic(deletedAtField, .equal, .null)
        let isFuture = DatabaseQuery.Filter.basic(deletedAtField, .greaterThan, .bind(Date()))
        query.filters.append(.group([isNull, isFuture], .or))
    }
}

@propertyWrapper
public final class Timestamp: AnyField, FieldRepresentable {
    public typealias Value = Date?

    public enum Trigger {
        case create
        case update
        case delete
    }

    public let field: Field<Date?>

    public let trigger: Trigger

    public var key: String {
        return self.field.key
    }

    var inputValue: DatabaseQuery.Value? {
        get {
            return self.field.inputValue
        }
        set {
            self.field.inputValue = newValue
        }
    }

    public var projectedValue: Timestamp {
        return self
    }

    public var wrappedValue: Date? {
        get {
            return self.field.wrappedValue
        }
        set {
            self.field.wrappedValue = newValue
        }
    }

    public init(key: String, on trigger: Trigger) {
        self.field = .init(key: key)
        self.trigger = trigger
    }

    public func touch(date: Date? = .init()) {
        self.inputValue = .bind(date)
    }

    func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

//public protocol Timestampable: Model, _AnyTimestampable {
//    var createdAt: Date? { get set }
//    var updatedAt: Date? { get set }
//}
//
//
//public protocol _AnyTimestampable {
//    var _createdAtField: Field<Date?> { get }
//    var _updatedAtField: Field<Date?> { get }
//}
//
//extension Timestampable {
//    public var _createdAtField: Field<Date?> {
//        guard let createdAt = Mirror(reflecting: self).descendant("_createdAt") else {
//            fatalError("createdAt must be declared using @Field")
//        }
//        return createdAt as! Field<Date?>
//    }
//
//    public var _updatedAtField: Field<Date?> {
//        guard let updatedAt = Mirror(reflecting: self).descendant("_updatedAt") else {
//            fatalError("updatedAt must be declared using @Field")
//        }
//        return updatedAt as! Field<Date?>
//    }
//}
