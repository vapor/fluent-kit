protocol AnyRow: class {
    var model: AnyModel.Type { get }
    var storage: Storage { get set }
}

@dynamicMemberLookup
public final class Row<Model>: Codable, CustomStringConvertible, AnyRow
    where Model: FluentKit.Model
{
    public var exists: Bool {
        return self.storage.exists
    }

    var model: AnyModel.Type {
        return Model.self
    }

    var storage: Storage

    init(storage: Storage) throws {
        self.storage = storage
        try self.storage.cacheOutput(for: Model.self)
    }

    public init() {
        self.storage = DefaultStorage(output: nil, eagerLoads: [:], exists: false)
    }

    public var description: String {
        let input: String
        if self.storage.input.isEmpty {
            input = "nil"
        } else {
            input = self.storage.input.description
        }
        let output: String
        if let o = self.storage.output {
            output = o.description
        } else {
            output = "nil"
        }
        return "\(Model.self)(input: \(input), output: \(output))"
    }

    // MARK: Fields

    public func has<Value>(_ field: KeyPath<Model, Field<Value>>) -> Bool {
        return self.has(Model.shared[keyPath: field].name)
    }

    public func has(_ fieldName: String) -> Bool {
        return self.storage.cachedOutput[fieldName] != nil
    }

    public func get<Value>(_ field: KeyPath<Model, Field<Value>>) -> Value {
        return self.get(Model.shared[keyPath: field].name)
    }

    public func get<Value>(_ fieldName: String, as value: Value.Type = Value.self) -> Value
        where Value: Codable
    {
        return self.storage.get(fieldName)
    }

    public func set<Value>(_ field: KeyPath<Model, Field<Value>>, to value: Value) {
        self.storage.set(Model.shared[keyPath: field].name, to: value)
    }

    public func set<Value>(_ fieldName: String, to value: Value)
        where Value: Codable
    {
        self.storage.set(fieldName, to: value)
    }

    // MARK: Join

    public func joined<Joined>(_ model: Joined.Type) throws -> Row<Joined>
        where Joined: FluentKit.Model
    {
        return try Row<Joined>(storage: DefaultStorage(
            output: self.storage.output!.prefixed(by: Joined.entity + "_"),
            eagerLoads: [:],
            exists: true
        ))
    }

    // MARK: Parent

    public subscript<Value>(dynamicMember field: KeyPath<Model, Parent<Value>>) -> RowParent<Value> {
        return RowParent(
            parent: Model.shared[keyPath: field],
            row: self
        )
    }

    // MARK: Children

    public subscript<Value>(dynamicMember field: KeyPath<Model, Children<Value>>) -> RowChildren<Value> {
        return RowChildren(
            children: Model.shared[keyPath: field],
            row: self
        )
    }

    // MARK: Dynamic Member Lookup

    public subscript<Value>(dynamicMember field: KeyPath<Model, Field<Value>>) -> Value {
        get {
            return self.get(field)
        }
        set {
            self.set(field, to: newValue)
        }
    }

    // MARK: Codable

    public convenience init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        for field in Model.shared.properties {
            do {
                try field.decode(from: decoder, to: self)
            } catch {
                print("Could not decode \(field.name): \(error)")
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for property in Model.shared.properties {
            try property.encode(to: &encoder, from: self)
        }
    }
}
