public protocol Model: AnyModel, CustomStringConvertible {
    associatedtype Properties: ModelProperties
        where Properties.Model == Self
    static var properties: Properties { get }
}


public protocol ModelProperties {
    associatedtype Model: FluentKit.Model
    associatedtype ID: ModelID
    var id: ModelField<Model, ID> { get }
    var all: [ModelProperty] { get }
}


extension ModelProperties {
    public var all: [Model.Property] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0 as? ModelProperty }
    }
}

extension Model {
    public typealias ID = Properties.ID
    public typealias Field<Value> = ModelField<Self, Value>
        where Value: Codable
    
    public typealias FieldKey<Value> = KeyPath<Properties, Field<Value>>
        where Value: Codable
    
    public static func field<T>(forKey key: FieldKey<T>) -> Field<T> {
        return self.properties[keyPath: key]
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

extension Model {
    public func get<Value>(_ key: FieldKey<Value>) throws -> Value {
        return try self.get(Self.field(forKey: key))
    }
    
    public func get<Value>(_ field: Field<Value>) throws -> Value {
        return try self.storage.get(field.name)
    }
    
    public func set<Value>(_ key: FieldKey<Value>, to value: Value) {
        self.set(Self.field(forKey: key), to: value)
    }
    
    public func set<Value>(_ field: Field<Value>, to value: Value) {
        self.storage.set(field.name, to: value)
    }
    
    #warning("TODO: better name")
    public func mut<Value>(_ key: FieldKey<Value>, _ closure: (inout Value) throws -> ()) throws {
        var value: Value = try self.get(key)
        try closure(&value)
        self.set(key, to: value)
    }
}

extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }
    
    public func create(on database: Database) -> EventLoopFuture<Void> {
        precondition(!self.exists)
        let builder = database.query(Self.self).set(self.storage.input)
        builder.query.action = .create
        return builder.run { model in
            #warning("for mysql, we might need to hold onto storage input")
            self.storage = DefaultModelStorage(
                output: model.storage.output,
                eagerLoads: model.storage.eagerLoads,
                exists: true
            )
        }
    }
    
    public func update(on database: Database) -> EventLoopFuture<Void> {
        precondition(self.exists)
        let builder = try! database.query(Self.self).filter(\.id == self.get(\.id)).set(self.storage.input)
        builder.query.action = .update
        return builder.run { model in
            self.storage = DefaultModelStorage(
                output: model.storage.output,
                eagerLoads: model.storage.eagerLoads,
                exists: true
            )
            #warning("for mysql, we might need to hold onto storage input")
        }
    }
    
    public func delete(on database: Database) -> EventLoopFuture<Void> {
        precondition(self.exists)
        let builder = try! database.query(Self.self).filter(\.id == self.get(\.id))
        builder.query.action = .delete
        return builder.run().map {
            self.storage.exists = false
        }
    }
}



extension Array where Element: Model {
    public func create(on database: Database) -> EventLoopFuture<Void> {
        let builder = database.query(Element.self)
        for model in self {
            precondition(!model.exists)
            builder.set(model.storage.input)
        }
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { model in
            let next = it.next()!
            next.storage = DefaultModelStorage(
                output: model.storage.output,
                eagerLoads: model.storage.eagerLoads,
                exists: true
            )
        }
    }
}
