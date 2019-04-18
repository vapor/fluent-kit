public protocol Model: class, Codable, CustomStringConvertible {
    associatedtype ID: ModelID
    var id: Field<ID> { get }
    var storage: Storage { get }
    init(storage: Storage)
    var properties: [Property] { get }
}

extension Model {
    public typealias Storage = ModelStorage
    
    public static var entity: String {
        return "\(Self.self)"
    }

    public init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        for property in self.properties {
            do {
                try property.decode(from: decoder)
            } catch {
                print("Could not decode \(property.name): \(error)")
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for property in self.properties {
            try property.encode(to: &encoder)
        }
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
        return "\(Self.self)(input: \(input), output: \(output))"
    }
}

extension Model {
    public static func find(_ id: Self.ID?, on database: Database) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return database.query(Self.self).filter(\.id == id).first()
    }
}

extension Model {
    public static var `default`: Self {
        #warning("TODO: optimize")
        return .init()
    }

    public init() {
        self.init(
            storage: DefaultModelStorage(output: nil, eagerLoads: [:], exists: false)
        )
    }

    public var properties: [Property] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? Property }
    }

    public var exists: Bool {
        switch self.id.storage {
        case .none, .input: return false
        case .output: return true
        }
    }
}

extension Model {
    internal init(loading storage: ModelStorage) throws {
        self.init(storage: storage)
        for property in self.properties {
            try property.load(from: storage)
        }
    }

    internal var input: [String: DatabaseQuery.Value] {
        let values = self.properties.compactMap { property -> (String, DatabaseQuery.Value)? in
            guard let value = property.input else {
                return nil
            }
            return (property.name, .bind(value))
        }
        return .init(uniqueKeysWithValues: values)
    }
}

//extension Model {
//    public static func new() -> Row {
//        return .init()
//    }
//}

//extension Model {
//    public var all: [ModelProperty] {
//        return Mirror(reflecting: self)
//            .children
//            .compactMap { $0.value as? ModelProperty }
//    }
//}

extension Model {
    public typealias Property = ModelProperty
    public typealias Field<Value> = ModelField<Self, Value>
        where Value: Codable
    
    public typealias FieldKey<Value> = KeyPath<Self, Field<Value>>
        where Value: Codable
    
    public static func field<T>(forKey key: FieldKey<T>) -> Field<T> {
        return self.default[keyPath: key]
    }
}

extension ModelStorage {
    public func get<Value>(_ name: String, as value: Value.Type = Value.self) throws -> Value
        where Value: Codable
    {
        if let input = self.input[name] {
            switch input {
            case .bind(let encodable): return encodable as! Value
            default: fatalError("Non-matching input.")
            }
        } else if let output = self.output {
            return try output.decode(field: name, as: Value.self)
        } else {
            throw ModelError.missingField(name: name)
        }
    }
    public mutating func set<Value>(_ name: String, to value: Value)
        where Value: Codable
    {
        self.input[name] = .bind(value)
    }
}

//extension ModelRow {
//    public func get<Value>(_ key: Model.FieldKey<Value>) throws -> Value
//        where Value: Codable
//    {
//        return try self.get(Model.field(forKey: key))
//    }
//
//    public func get<Value>(_ field: Model.Field<Value>) throws -> Value
//        where Value: Codable
//    {
//        return try self.storage.get(field.name)
//    }
//
//    public func set<Value>(_ key: Model.FieldKey<Value>, to value: Value)
//        where Value: Codable
//    {
//        self.set(Model.field(forKey: key), to: value)
//    }
//
//    public func set<Value>(_ field: Model.Field<Value>, to value: Value)
//        where Value: Codable
//    {
//        self.storage.set(field.name, to: value)
//    }
//
//    #warning("TODO: better name")
//    public func mut<Value>(_ key: Model.FieldKey<Value>, _ closure: (inout Value) throws -> ()) throws
//        where Value: Codable
//    {
//        var value: Value = try self.get(key)
//        try closure(&value)
//        self.set(key, to: value)
//    }
//}

extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        return database.save(self)
    }
    
    public func create(on database: Database) -> EventLoopFuture<Void> {
        return database.create(self)
    }
    
    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.update(self)
    }
    
    public func delete(on database: Database) -> EventLoopFuture<Void> {
        return database.delete(self)
    }
}

#warning("TODO: possible to extend array of model?")
extension Database {
    public func create<Model>(_ models: [Model]) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        let builder = self.query(Model.self)
        models.forEach { model in
            precondition(!model.exists)
            builder.set(model.input)
        }
        builder.query.action = .create
        var it = models.makeIterator()
        return builder.run { created in
            let next = it.next()!
            #warning("TODO: set model exists = true")
            // next.id.storage = .output(0)
        }
    }
}

private extension Database {
    func save<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        if model.exists {
            return self.update(model)
        } else {
            return self.create(model)
        }
    }
    
    func create<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        precondition(!model.exists)
        let builder = self.query(Model.self).set(model.input)
        builder.query.action = .create
        return builder.run { created in
            #warning("for mysql, we might need to hold onto storage input")
            model.id.storage = try .output(created.storage.output!.decode(field: "fluentID", as: Model.ID.self))
        }
    }
    
    func update<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        precondition(model.exists)
        let builder = self.query(Model.self)
            .filter(\.id == model.id.value)
            .set(model.input)
        builder.query.action = .update
        return builder.run { updated in
            // ignore
        }
    }
    
    func delete<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        let builder = self.query(Model.self)
            .filter(\.id == model.id.value)
        builder.query.action = .delete
        return builder.run().map {
            model.id.storage = .none
        }
    }
}
