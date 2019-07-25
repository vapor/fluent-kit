@propertyWrapper
public final class Field<Value>: AnyField
    where Value: Codable
{
    let nameOverride: String?
    var _storage: Storage?
    var label: String?
    var modelType: AnyModel.Type?

    public var type: Any.Type {
        return Value.self
    }

    public var projectedValue: Field<Value> {
        return self
    }
    
    public var wrappedValue: Value {
        get {
            if let input = self.storage.input[self.name] {
                switch input {
                case .bind(let encodable):
                    guard let value = encodable as? Value else {
                        fatalError("Unexpected input value type: \(Swift.type(of: encodable))")
                    }
                    return value
                default:
                    fatalError("Unexpected input value case: \(input)")
                }
            } else if let output = self.storage.output, output.contains(field: self.name) {
                do {
                    return try output.decode(field: self.name, as: Value.self)
                } catch {
                    fatalError("Failed to decode output: \(error)")
                }
            } else {
                if let label = self.label {
                    print(self.storage.output)
                    fatalError("Field was not fetched during query: \(label)")
                } else {
                    fatalError("Cannot access field before it is initialized")
                }
            }
        }
        set {
            self.storage.input[self.name] = .bind(newValue)
        }
    }

    public init() {
        self.nameOverride = nil
    }

    public init(_ nameOverride: String) {
        self.nameOverride = nameOverride
    }

    func encode(to encoder: inout ModelEncoder) throws {
        try encoder.encode(self.wrappedValue, forKey: self.label!)
    }

    func decode(from decoder: ModelDecoder) throws {
        self.wrappedValue = try decoder.decode(Value.self, forKey: self.label!)
    }
}
