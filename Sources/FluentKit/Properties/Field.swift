@propertyWrapper
public final class Field<Value>: AnyField
    where Value: Codable
{
    let key: String?
    var output: Value?
    var input: Value?

    public var projectedValue: Field<Value> {
        return self
    }
    
    public var wrappedValue: Value {
        get {
            if let input = self.input {
                return input
            } else if let output = self.output {
                return output
            } else {
                fatalError("Cannot access field before it is initialized or fetched")
            }
        }
        set {
            self.input = newValue
        }
    }

    public init() {
        self.key = nil
    }

    public init(_ key: String) {
        self.key = key
    }

    // MARK: Field

    func key(label: String) -> String {
        return self.key ?? label.convertedToSnakeCase()
    }

    // MARK: Property

    func setOutput(from output: DatabaseOutput, label: String) throws {
        self.output = try output.decode(field: self.key(label: label), as: Value.self)
    }

    func getInput() -> DatabaseQuery.Value? {
        return self.input.flatMap { .bind($0) }
    }

    func encode(to encoder: inout ModelEncoder, label: String) throws {
        try encoder.encode(self.wrappedValue, forKey: label)
    }

    func decode(from decoder: ModelDecoder, label: String) throws {
        self.wrappedValue = try decoder.decode(Value.self, forKey: label)
    }
}
