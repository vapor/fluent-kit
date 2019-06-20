@propertyWrapper
public final class ID<Value>: AnyField
    where Value: Codable
{
    let field: Field<Value?>
    var storage: Storage?

    public var wrappedValue: Value? {
        get {
            return self.field.wrappedValue
        }
        set {
            self.field.wrappedValue = newValue
        }
    }

    public var wrapperValue: ID<Value> {
        return self
    }

    var name: String {
        return self.field.name
    }

    var type: Any.Type {
        return self.field.type
    }

    var input: DatabaseQuery.Value? {
        return self.field.input
    }

    public convenience init() {
        self.init(nameOverride: nil)
    }

    public convenience init(_ nameOverride: String) {
        self.init(nameOverride: nameOverride)
    }

    init(nameOverride: String?) {
        self.field = .init(nameOverride: nameOverride)
    }

    func encode(to encoder: inout ModelEncoder) throws {
        try self.field.encode(to: &encoder)
    }

    func decode(from decoder: ModelDecoder) throws {
        try self.field.decode(from: decoder)
    }

    func load(from storage: Storage) throws {
        self.storage = storage
        try self.field.load(from: storage)
    }
}
