extension Fields {
    public typealias OptionalField<Value> = OptionalFieldProperty<Self, Value>
        where Value: Codable
}

@propertyWrapper
public final class OptionalFieldProperty<Model, Value>
    where Model: FluentKit.Fields, Value: Codable
{
    public let key: FieldKey
    var outputValue: Value?
    var inputValue: DatabaseQuery.Value?
    var converter: AnyFieldValueConverter<Optional<Value>>

    public var projectedValue: OptionalFieldProperty<Model, Value> {
        self
    }

    public var wrappedValue: Value? {
        get {
            self.value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.key = key
        self.converter = AnyFieldValueConverter(DefaultFieldValueConverter(Model.self, key: key))
    }

    public init<Converter>(key: FieldKey, converter: Converter) where Converter: FieldValueConverter, Converter.Value == Optional<Value> {
        self.key = key
        self.converter = AnyFieldValueConverter(converter)
    }
}

extension OptionalFieldProperty: PropertyProtocol {
    public var value: Value? {
        get {
            if let value = self.inputValue.flatMap(self.converter.value(from:)) {
                return value
            } else if let value = self.outputValue {
                return value
            } else {
                return nil
            }
        }
        set {
            self.inputValue = self.converter.databaseValue(from: newValue)
        }
    }
}

extension OptionalFieldProperty: FieldProtocol { }

extension OptionalFieldProperty: AnyField {

}

extension OptionalFieldProperty: AnyProperty {
    public var nested: [AnyProperty] {
        []
    }

    public var path: [FieldKey] {
        [self.key]
    }

    public func input(to input: inout DatabaseInput) {
        input.values[self.key] = self.inputValue
    }

    public func output(from output: DatabaseOutput) throws {
        if output.contains(self.key) {
            self.inputValue = nil
            do {
                self.outputValue = try self.converter.decode(from: output)
            } catch {
                throw FluentError.invalidField(
                    name: self.key.description,
                    valueType: Value.self,
                    error: error
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try self.converter.encode(self.wrappedValue, to: &container)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = nil
        } else {
            self.value = try self.converter.decode(from: container)
        }
    }
}
