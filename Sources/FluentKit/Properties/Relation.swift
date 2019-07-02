public protocol RelationValue {
    associatedtype Value: Model
    init(_ name: String)
}

@propertyWrapper
public final class Relation<Value>
    where Value: RelationValue
{
    public var wrappedValue: Value

    public init(_ name: String) {
        self.wrappedValue = .init(name)
    }
}

extension Relation: AnyProperty where Value: AnyProperty {
    var label: String? {
        get {
            return self.wrappedValue.label
        }
        set {
            self.wrappedValue.label = newValue
        }
    }

    func encode(to encoder: inout ModelEncoder) throws {
        try self.wrappedValue.encode(to: &encoder)
    }

    func decode(from decoder: ModelDecoder) throws {
        try self.wrappedValue.decode(from: decoder)
    }

    func setOutput(from storage: Storage) throws {
        try self.wrappedValue.setOutput(from: storage)
    }
}

extension Relation: AnyField where Value: AnyField {
    var nameOverride: String? {
        return self.wrappedValue.nameOverride
    }

    var type: Any.Type {
        return self.wrappedValue.type
    }

    func setInput(to input: inout [String : DatabaseQuery.Value]) {
        self.wrappedValue.setInput(to: &input)
    }
}
