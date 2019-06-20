public protocol RelationValue {
    associatedtype Value: Model
    init(nameOverride: String?)
}

@propertyWrapper
public final class Relation<Value>
    where Value: RelationValue
{
    public var wrappedValue: Value

    public init() {
        self.wrappedValue = .init(nameOverride: nil)
    }

    public init(_ nameOverride: String) {
        self.wrappedValue = .init(nameOverride: nameOverride)
    }
}

extension Relation: AnyProperty where Value: AnyProperty {
    func encode(to encoder: inout ModelEncoder) throws {
        try self.wrappedValue.encode(to: &encoder)
    }

    func decode(from decoder: ModelDecoder) throws {
        try self.wrappedValue.decode(from: decoder)
    }

    func load(from storage: Storage) throws {
        try wrappedValue.load(from: storage)
    }
}

extension Relation: AnyField where Value: AnyField {
    var name: String {
        return self.wrappedValue.name
    }

    var type: Any.Type {
        return self.wrappedValue.type
    }

    var input: DatabaseQuery.Value? {
        return self.wrappedValue.input
    }
}
