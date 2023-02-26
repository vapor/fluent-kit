extension Model {
    public typealias CompositeID<Value> = CompositeIDProperty<Self, Value>
        where Value: Fields
}

// MARK: Type

@propertyWrapper @dynamicMemberLookup
public final class CompositeIDProperty<Model, Value>
    where Model: FluentKit.Model, Value: FluentKit.Fields
{
    public var value: Value?
    public var exists: Bool
    var cachedOutput: DatabaseOutput?

    public var projectedValue: CompositeIDProperty<Model, Value> { self }
    
    public var wrappedValue: Value? {
        get { return self.value }
        set { self.value = newValue }
    }

    public init() {
        self.value = .init()
        self.exists = false
        self.cachedOutput = nil
    }

    public subscript<Nested>(
         dynamicMember keyPath: KeyPath<Value, Nested>
    ) -> Nested
        where Nested: Property
    {
        return self.value![keyPath: keyPath]
    }
}

extension CompositeIDProperty: CustomStringConvertible {
    public var description: String {
        "@\(Model.self).CompositeID<\(Value.self))>()"
    }
}

// MARK: Property

extension CompositeIDProperty: AnyProperty, Property {}

// MARK: Database

extension CompositeIDProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        Value.keys
    }

    public func input(to input: DatabaseInput) {
        self.value!.input(to: input)
    }

    public func output(from output: DatabaseOutput) throws {
        self.exists = true
        self.cachedOutput = output
        try self.value!.output(from: output)
    }
}

// MARK: Codable

extension CompositeIDProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Value?.self)
    }
}

// MARK: AnyID

extension CompositeIDProperty: AnyID {
    func generate() {}
}
