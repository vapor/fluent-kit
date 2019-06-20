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

    var name: String {
        return self.idField.name
    }

    var input: DatabaseQuery.Value? {
        return self.idField.input
    }

    public init(nameOverride: String?) {
        self.idField = .init(nameOverride: nameOverride)
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

    func load(from storage: Storage) throws {
        try self.idField.load(from: storage)
        if let eagerLoad = storage.eagerLoads[Value.entity] {
            self.eagerLoadedValue = try eagerLoad.get(id: self.id)
                .map { $0 as! Value }
                .first!
        }
    }
    
    func encode(to encoder: inout ModelEncoder) throws {
        if let parent = self.eagerLoadedValue {
            try encoder.encode(parent, forKey: Value.name)
        } else {
            try encoder.encode(self.id, forKey: self.name)
        }
    }
    
    func decode(from decoder: ModelDecoder) throws {
        self.id = try decoder.decode(Value.ID.self, forKey: self.name)
    }
}
