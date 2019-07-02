public final class Parent<Value>: RelationValue, AnyField
    where Value: Model
{
    private let idField: Field<Value.ID>
    private var eagerLoadedValue: Value?

    public var id: Value.ID {
        get {
            return self.idField.wrappedValue
        }
        set {
            self.idField.wrappedValue = newValue
        }
    }

    var type: Any.Type {
        return self.idField.type
    }

    var nameOverride: String? {
        return self.idField.nameOverride
    }

    var label: String? {
        get {
            return self.idField.label
        }
        set {
            self.idField.label = newValue
        }
    }

    public init(_ key: String) {
        self.idField = .init(key)
    }

    public var isEagerLoaded: Bool {
        return self.eagerLoadedValue != nil
    }

    public func eagerLoaded() throws -> Value {
        guard let eagerLoaded = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: Value.entity.self)
        }
        return eagerLoaded
    }

    public func query(on database: Database) -> QueryBuilder<Value> {
        return Value.query(on: database)
            .filter(self.name, .equal, self.id)
    }


    public func get(on database: Database) -> EventLoopFuture<Value> {
        return self.query(on: database).first().map { parent in
            guard let parent = parent else {
                fatalError()
            }
            return parent
        }
    }

    func setInput(to input: inout [String : DatabaseQuery.Value]) {
        self.idField.setInput(to: &input)
    }

    func setOutput(from storage: Storage) throws {
        try self.idField.setOutput(from: storage)
        if let eagerLoad = storage.eagerLoads[Value.entity] {
            self.eagerLoadedValue = try eagerLoad.get(id: self.id)
                .map { $0 as! Value }
                .first!
        }
    }
    
    func encode(to encoder: inout ModelEncoder) throws {
        if let parent = self.eagerLoadedValue {
            try encoder.encode(parent, forKey: self.label!)
        } else {
            try encoder.encode([
                Value.reference.idField.name: self.id
            ], forKey: self.label!)
        }
    }
    
    func decode(from decoder: ModelDecoder) throws {
        self.id = try decoder.decode(Value.ID.self, forKey: self.label!)
    }
}
