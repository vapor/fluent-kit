public final class Children<Value>: RelationValue, AnyProperty
    where Value: Model
{
    let nameOverride: String?
    var label: String?

    private var eagerLoadedValue: [Value]?
    private var id: Value.ID?

    public init(_ nameOverride: String) {
        self.nameOverride = nameOverride
    }

    public func eagerLoaded() throws -> [Value] {
        guard let rows = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: Value.entity.self)
        }
        return rows
    }

    var childName: String {
        #warning("FIXME: use model entity + id")
        return "self_id"
    }

    public func query(on database: Database) -> QueryBuilder<Value> {
        guard let id = self.id else {
            fatalError("Cannot form children query without model id")
        }
        return Value.query(on: database)
            .filter(self.childName, .equal, id)
    }

    func setOutput(from storage: Storage) throws {
        #warning("FIXME: pass correct id using Model info")
        self.id = try storage.output!.decode(field: "id", as: Value.ID.self)
        if let eagerLoad = storage.eagerLoads[Value.entity] {
            self.eagerLoadedValue = try eagerLoad.get(id: self.id!)
                .map { $0 as! Value }
        }
    }

    func encode(to encoder: inout ModelEncoder) throws {
        if let rows = self.eagerLoadedValue {
            try encoder.encode(rows, forKey: self.label!)
        }
    }
    
    func decode(from decoder: ModelDecoder) throws {
        // don't decode
    }
}
