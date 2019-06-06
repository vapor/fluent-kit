public struct Parent<T>: RelationType where T: Model {
    public init() {
        self.value = .init()
    }

    var value: T

    public var id: T.ID? {
        get {
            return self.value.id
        }
        set {
            self.value.id = newValue
        }
    }
//
//    public func eagerLoaded() throws -> Row<Value> {
//        guard let row = try self.parent.eagerLoaded(for: self.row) else {
//            throw FluentError.missingEagerLoad(name: Value.entity.self)
//        }
//        return row
//    }
//
//    public func query(on database: Database) -> QueryBuilder<Value> {
//        let id = self.row.storage.get(self.parent.name, as: Value.ID.self)
//        return Value.query(on: database)
//            .filter(self.parent.name, .equal, id)
//    }
//
//
//    public func get(on database: Database) -> EventLoopFuture<Row<Value>> {
//        return self.query(on: database).first().map { parent in
//            guard let parent = parent else {
//                fatalError()
//            }
//            return parent
//        }
//    }
}


//public struct Parent<Value>: AnyField
//    where Value: Model
//{
//    public var type: Any.Type {
//        return Value.ID.self
//    }
//
//    public let name: String
//    public let dataType: DatabaseSchema.DataType?
//    public var constraints: [DatabaseSchema.FieldConstraint]
//
//    public init(
//        _ name: String,
//        dataType: DatabaseSchema.DataType? = nil,
//        constraints: DatabaseSchema.FieldConstraint...
//    ) {
//        self.name = name
//        self.dataType = dataType
//        self.constraints = constraints
//    }
//
//    func cached(from output: DatabaseOutput) throws -> Any? {
//        guard output.contains(field: self.name) else {
//            return nil
//        }
//        return try output.decode(field: self.name, as: Value.ID.self)
//    }
//
//    func eagerLoaded(for row: AnyRow) throws -> Row<Value>? {
//        guard let cache = row.storage.eagerLoads[Value.entity] else {
//            return nil
//        }
//        return try cache.get(id: row.storage.get(self.name, as: Value.ID.self))
//            .map { $0 as! Row<Value> }
//            .first!
//    }
//
//    func encode(to encoder: inout ModelEncoder, from row: AnyRow) throws {
//        if let parent = try self.eagerLoaded(for: row) {
//            try encoder.encode(parent, forKey: Value.name)
//        } else {
//            try encoder.encode(row.storage.get(self.name, as: Value.ID.self), forKey: self.name)
//        }
//    }
//
//    func decode(from decoder: ModelDecoder, to row: AnyRow) throws {
//        try row.storage.set(self.name, to: decoder.decode(Value.ID.self, forKey: self.name))
//    }
//}
