@propertyWrapper
public final class Field<Value>: AnyField
    where Value: Codable
{
    let key: String?
    var outputValue: Value?
    var inputValue: Value?
    var cachedOutput: DatabaseOutput?
    var exists: Bool

    public var projectedValue: Field<Value> {
        return self
    }
    
    public var wrappedValue: Value {
        get {
            if let value = self.inputValue {
                return value
            } else if let value = self.outputValue {
                return value
            } else {
                fatalError("Cannot access field before it is initialized or fetched")
            }
        }
        set {
            self.inputValue = newValue
        }
    }

    public init() {
        self.key = nil
        self.exists = false
    }

    public init(_ key: String) {
        self.key = key
        self.exists = false
    }

    // MARK: Field

    func key(label: String) -> String {
        return self.key ?? label.convertedToSnakeCase()
    }

    func input() -> DatabaseQuery.Value? {
        return self.inputValue.flatMap { .bind($0) }
    }

    // MARK: Property

    func output(from output: DatabaseOutput, label: String) throws {
        self.exists = true
        self.cachedOutput = output
        
        let key = self.key(label: label)
        if output.contains(field: key) {
            self.inputValue = nil
            self.outputValue = try output.decode(field: key, as: Value.self)
        }
    }

    func encode(to encoder: inout ModelEncoder, label: String) throws {
        try encoder.encode(self.wrappedValue, forKey: label)
    }

    func decode(from decoder: ModelDecoder, label: String) throws {
        self.wrappedValue = try decoder.decode(Value.self, forKey: label)
    }
}
