extension Model {
    public typealias CompositeID<Value> = CompositeIDProperty<Self, Value>
        where Value: Fields
}

// MARK: Type

@propertyWrapper
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
        guard Value.init().properties.allSatisfy({ $0 is AnyQueryAddressableProperty }) else {
            fatalError("""
                All elements of a composite model ID must represent exactly one actual column in the database.
                
                This error is most often caused by trying to use @Children, @Siblings, or @Group inside a @CompositeID.
                """)
        }
        self.value = .init()
        self.exists = false
        self.cachedOutput = nil
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
        try self.value!.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        self.value = try .init(from: decoder)
    }
}

// MARK: AnyID

extension CompositeIDProperty: AnyID {
    func generate() {}
}
