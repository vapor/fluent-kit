@dynamicMemberLookup
public final class NestedProperty<Model, Property>
    where Model: Fields, Property: PropertyProtocol
{
    public let prefix: [FieldKey]
    public let property: Property

    init(prefix: [FieldKey], property: Property) {
        self.prefix = prefix
        self.property = property
    }

    public subscript<Property>(
        dynamicMember keyPath: KeyPath<Value, Property>
    ) -> NestedProperty<Model, Property> {
        .init(prefix: self.path, property: self.value![keyPath: keyPath])
    }
}

extension NestedProperty: FieldProtocol where Property: FieldProtocol { }
extension NestedProperty: AnyField where Property: AnyField { }

extension NestedProperty: PropertyProtocol {
    public var path: [FieldKey] {
        self.prefix + self.property.path
    }

    public typealias Model = Property.Model
    public typealias Value = Property.Value

    public var value: Value? {
        get {
            self.property.value
        }
        set {
            self.property.value = newValue
        }
    }
}

extension NestedProperty: AnyProperty {
    public var fields: [AnyField] {
        self.property.fields
    }

    public func input(to input: inout DatabaseInput) {
        self.property.input(to: &input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.property.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try self.property.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.property.decode(from: decoder)
    }

}
