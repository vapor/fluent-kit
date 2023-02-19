extension Fields {
    public typealias Group<Value> = GroupProperty<Self, Value>
        where Value: Fields
}

// MARK: Type

@propertyWrapper @dynamicMemberLookup
public final class GroupProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let key: FieldKey
    public var value: Value?

    public var projectedValue: GroupProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value {
        get {
            guard let value = self.value else {
                fatalError("Cannot access uninitialized Group field: \(self.description)")
            }
            return value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.key = key
        self.value = .init()
    }

    public subscript<Nested>(
         dynamicMember keyPath: KeyPath<Value, Nested>
    ) -> GroupPropertyPath<Model, Nested>
        where Nested: Property
    {
        return .init(key: self.key, property: self.value![keyPath: keyPath])
    }
}

extension GroupProperty: CustomStringConvertible {
    public var description: String {
        "@\(Model.self).Group<\(Value.self)>(key: \(self.key))"
    }
}

// MARK: + Property

extension GroupProperty: AnyProperty { }

extension GroupProperty: Property { }

// MARK: + Database

extension GroupProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        Value.keys.map {
            .prefix(.prefix(self.key, .string("_")), $0)
        }
    }

    private var prefix: FieldKey {
        .prefix(self.key, .string("_"))
    }

    public func input(to input: DatabaseInput) {
        self.value?.input(to: input.prefixed(by: self.prefix))
    }

    public func output(from output: DatabaseOutput) throws {
        if self.value == nil { self.value = .init() }
        try self.value!.output(from: output.prefixed(by: self.prefix))
    }
}

// MARK: + Codable

extension GroupProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        try self.value?.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        guard !container.decodeNil() else { return }
        self.value = .some(try container.decode(Value.self))
    }
    
    public var skipPropertyEncoding: Bool { self.value == nil }
}


// MARK: Path

@dynamicMemberLookup
public final class GroupPropertyPath<Model, Property>
    where Model: Fields
{
    let key: FieldKey
    let property: Property

    init(key: FieldKey, property: Property) {
        self.key = key
        self.property = property
    }

    public subscript<Nested>(
         dynamicMember keyPath: KeyPath<Property, Nested>
    ) -> GroupPropertyPath<Model, Nested> {
        .init(
            key: self.key,
            property: self.property[keyPath: keyPath]
        )
    }
}

// MARK: + Property

extension GroupPropertyPath: AnyProperty
    where Property: AnyProperty
{
    public static var anyValueType: Any.Type {
        Property.anyValueType
    }

    public var anyValue: Any? {
        self.property.anyValue
    }
}

extension GroupPropertyPath: FluentKit.Property
    where Property: FluentKit.Property
{
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

// MARK: + Queryable

extension GroupPropertyPath: AnyQueryableProperty
    where Property: QueryableProperty
{
    public var path: [FieldKey] {
        let subPath = self.property.path
        return [
            .prefix(.prefix(self.key, .string("_")), subPath[0])
        ] + subPath[1...]
    }
}

extension GroupPropertyPath: QueryableProperty
    where Property: QueryableProperty
{
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        Property.queryValue(value)
    }
}

// MARK: + QueryAddressable

extension GroupPropertyPath: AnyQueryAddressableProperty
    where Property: AnyQueryAddressableProperty
{
    public var anyQueryableProperty: AnyQueryableProperty {
        self.property.anyQueryableProperty
    }
    
    public var queryablePath: [FieldKey] {
        let subPath = self.property.queryablePath
        return [
            .prefix(.prefix(self.key, .string("_")), subPath[0])
        ] + subPath[1...]
    }
}

extension GroupPropertyPath: QueryAddressableProperty
    where Property: QueryAddressableProperty
{
    public typealias QueryablePropertyType = Property.QueryablePropertyType
    
    public var queryableProperty: QueryablePropertyType {
        self.property.queryableProperty
    }
}
