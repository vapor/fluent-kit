import NIOConcurrencyHelpers

extension Model {
    public typealias CompositeID<Value> = CompositeIDProperty<Self, Value>
    where Value: Fields
}

// MARK: Type

@propertyWrapper @dynamicMemberLookup
public final class CompositeIDProperty<Model, Value>: @unchecked Sendable
where Model: FluentKit.Model, Value: FluentKit.Fields {
    public var value: Value? = .init(.init())
    public var exists: Bool = false
    var cachedOutput: (any DatabaseOutput)?

    public var projectedValue: CompositeIDProperty<Model, Value> { self }

    public var wrappedValue: Value? {
        get { self.value }
        set { self.value = newValue }
    }

    public init() {}

    public subscript<Nested>(
        dynamicMember keyPath: KeyPath<Value, Nested>
    ) -> Nested
    where Nested: Property {
        self.value![keyPath: keyPath]
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

    public func input(to input: any DatabaseInput) {
        if let value = self.value {
            value.input(to: input)
        }
    }

    public func output(from output: any DatabaseOutput) throws {
        self.exists = true
        self.cachedOutput = output
        try self.value!.output(from: output)
    }
}

// MARK: Codable

extension CompositeIDProperty: AnyCodableProperty {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }

    public func decode(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Value?.self)
    }
}

// MARK: AnyID

extension CompositeIDProperty: AnyID {
    func generate() {}
}
