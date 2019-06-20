@propertyWrapper
public final class Field<Value>: AnyField
    where Value: Codable
{
    private let nameOverride: String?
    private var label: String?
    private var output: Value?
    private var _input: Value?
    private var didLoad: Bool

    var input: DatabaseQuery.Value? {
        return self._input.flatMap { .bind($0) }
    }

    public var type: Any.Type {
        return Value.self
    }
    
    public var wrappedValue: Value {
        get {
            if let input = self._input {
                return input
            } else if let output = self.output {
                return output
            } else {
                if self.didLoad {
                    fatalError("Field \(self.name) was not fetched during query")
                } else {
                    fatalError("Cannot access \(self.name) before it is initialized")
                }
            }
        }
        set {
            self._input = newValue
        }
    }

    public var name: String {
        guard let name = self.nameOverride ?? self.label else {
            fatalError("No label or name override set for \(self)")
        }
        return name
    }

    public convenience init() {
        self.init(nameOverride: nil)
    }

    public convenience init(_ nameOverride: String) {
        self.init(nameOverride: nameOverride)
    }
    
    internal init(nameOverride: String?) {
        self.nameOverride = nameOverride
        self.didLoad = false
    }

    func load(from storage: Storage) throws {
        self.didLoad = true
        guard let output = storage.output else {
            return
        }
        guard output.contains(field: self.name) else {
            return
        }
        self.output = try output.decode(field: self.name, as: Value.self)
    }
    
    func encode(to encoder: inout ModelEncoder) throws {
        try encoder.encode(self.wrappedValue, forKey: self.name)
    }

    func decode(from decoder: ModelDecoder) throws {
        self.wrappedValue = try decoder.decode(Value.self, forKey: self.name)
    }
}
