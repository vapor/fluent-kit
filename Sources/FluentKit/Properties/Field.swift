@propertyWrapper
public final class Field<Value>: AnyField
    where Value: Codable
{
    let nameOverride: String?
    var storage: Storage?
    var label: String?

    private var output: Value?
    private var input: Value?

    public var type: Any.Type {
        return Value.self
    }

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
                if let label = self.label {
                    fatalError("Field \(label) was not fetched during query")
                } else {
                    fatalError("Cannot access field before it is initialized")
                }
            }
        }
        set {
            self.input = newValue
        }
    }

    public init() {
        self.nameOverride = nil
    }

    public init(_ nameOverride: String) {
        self.nameOverride = nameOverride
    }

    func setInput(to input: inout [String : DatabaseQuery.Value]) {
        input[self.name] = self.input.flatMap { .bind($0) }
    }

    func setOutput(from storage: Storage) throws {
        self.storage = storage
        guard let output = storage.output else {
            return
        }
        guard output.contains(field: self.name) else {
            return
        }
        self.output = try output.decode(field: self.name, as: Value.self)
    }
    
    func encode(to encoder: inout ModelEncoder) throws {
        try encoder.encode(self.wrappedValue, forKey: self.label!)
    }

    func decode(from decoder: ModelDecoder) throws {
        self.wrappedValue = try decoder.decode(Value.self, forKey: self.label!)
    }
}
