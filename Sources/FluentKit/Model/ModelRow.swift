@dynamicMemberLookup
public final class ModelRow<Model>: Codable, CustomStringConvertible
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

    public subscript<Value>(dynamicMember field: Model.FieldKey<Value>) -> Value
        where Value: Codable
    {
        get {
            return self.get(Model.field(forKey: field))
        }
        set {
            self.set(Model.field(forKey: field), to: newValue)
        }
    }

    public func has<Value>(_ field: Model.FieldKey<Value>) -> Bool
        where Value: Codable
    {
        return self.storage.cachedOutput[Model.field(forKey: field).name] != nil
    }

    internal func get<Value>(_ field: Model.Field<Value>) -> Value
        where Value: Codable
    {
        return self.storage.get(field.name)
    }

    internal func set<Value>(_ field: Model.Field<Value>, to value: Value)
        where Value: Codable
    {
        self.storage.set(field.name, to: value)
    }

    // MARK: Parent

    public subscript<ParentType>(dynamicMember key: Model.ParentKey<ParentType>) -> ParentType.Row
        where ParentType: FluentKit.Model
    {
        get {
            guard let cache = self.storage.eagerLoads[ParentType.entity] else {
                fatalError("No cache set on storage.")
            }
            return try! cache.get(id: self.get(Model.parent(forKey: key).id))
                .map { $0 as! ParentType.Row }
                .first!
        }
        set {
            self.set(Model.parent(forKey: key).id, to: newValue.id!)
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
