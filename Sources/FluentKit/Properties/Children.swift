public final class Children<Value>: RelationValue, AnyProperty
    where Value: Model
{
    private let nameOverride: String?
    private var label: String?
    private var eagerLoadedValue: [Value]?
    private var id: Value.ID?

    var name: String {
        guard let name = self.nameOverride ?? self.label else {
            fatalError("No label or name override set for \(self)")
        }
        return name
    }

    public init(nameOverride: String?) {
        self.nameOverride = nameOverride
    }

    public func eagerLoaded() throws -> [Value] {
        guard let rows = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: Value.entity.self)
        }
        return rows
    }

    public func query(on database: Database) -> QueryBuilder<Value> {
        #warning("FIXME: pass correct id")
        return Value.query(on: database)
            .filter(self.name, .equal, self.id!)
    }

    func load(from storage: Storage) throws {
        #warning("FIXME: pass correct id")
        self.id = try storage.output!.decode(field: "id", as: Value.ID.self)
        if let eagerLoad = storage.eagerLoads[Value.entity] {
            self.eagerLoadedValue = try eagerLoad.get(id: self.id!)
                .map { $0 as! Value }
        }
    }

    func encode(to encoder: inout ModelEncoder) throws {
        if let rows = self.eagerLoadedValue {
            try encoder.encode(rows, forKey: Value.entity)
        }
    }
    
    func decode(from decoder: ModelDecoder) throws {
        // don't decode
    }
}
