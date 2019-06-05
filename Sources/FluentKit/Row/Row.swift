@dynamicMemberLookup
public final class Row<Model>: Codable, CustomStringConvertible
    where Model: FluentKit.Model
{
    public var exists: Bool {
        #warning("support changing id")
        return self.storage.exists
    }

    var storage: ModelStorage

    init(storage: ModelStorage) throws {
        self.storage = storage
        try self.storage.cacheOutput(for: Model.self)
    }

    public init() {
        self.storage = DefaultModelStorage(output: nil, eagerLoads: [:], exists: false)
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

    // MARK: Parent

    public subscript<Parent>(dynamicMember key: Model.ParentKey<Parent>) -> RowParent<Model, Parent>
        where Parent: FluentKit.Model
    {
        return RowParent(row: self, key: key)
    }

    // MARK: Children

    public func query<Child>(_ key: Model.ChildrenKey<Child>, on database: Database) -> QueryBuilder<Child>
        where Child: FluentKit.Model
    {
        let children = Model.children(forKey: key)
        return Child.query(on: database)
            .filter(children.id.name, .equal, self.id!)
    }

    public subscript<Child>(dynamicMember key: Model.ChildrenKey<Child>) -> [Row<Child>]
        where Child: FluentKit.Model
    {
        guard let cache = self.storage.eagerLoads[Child.entity] else {
            fatalError("No cache set on storage.")
        }
        return try! cache.get(id: self.id!)
            .map { $0 as! Row<Child> }
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
        for field in Model.shared.all {
            do {
                try field.decode(from: decoder, to: &self.storage)
            } catch {
                print("Could not decode \(field.name): \(error)")
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for property in Model.shared.all {
            try property.encode(to: &encoder, from: self.storage)
        }
    }
}
