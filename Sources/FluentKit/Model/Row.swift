//protocol AnyRow: class {
//    var model: AnyModel.Type { get }
//    var storage: Storage { get set }
//}
//
//@dynamicMemberLookup
//public final class Row<Model>: Codable, CustomStringConvertible, AnyRow
//    where Model: FluentKit.Model
//{
//    public var exists: Bool {
//        return self.storage.exists
//    }
//
//    var model: AnyModel.Type {
//        return Model.self
//    }
//
//    var storage: Storage
//
//    init(storage: Storage) throws {
//        self.storage = storage
//        try self.storage.cacheOutput(for: Model.self)
//    }
//
//    public init() {
//        self.storage = DefaultStorage(output: nil, eagerLoads: [:], exists: false)
//    }
//
//    // MARK: Fields
//
//    public func has<Value>(_ field: KeyPath<Model, Field<Value>>) -> Bool {
//        return self.has(Model.shared[keyPath: field].name)
//    }
//
//    public func has(_ fieldName: String) -> Bool {
//        return self.storage.cachedOutput[fieldName] != nil
//    }
//
//    public func get<Value>(_ field: KeyPath<Model, Field<Value>>) -> Value {
//        return self.get(Model.shared[keyPath: field].name)
//    }
//
//    public func get<Value>(_ fieldName: String, as value: Value.Type = Value.self) -> Value
//        where Value: Codable
//    {
//        return self.storage.get(fieldName)
//    }
//
//    public func set<Value>(_ field: KeyPath<Model, Field<Value>>, to value: Value) {
//        self.storage.set(Model.shared[keyPath: field].name, to: value)
//    }
//
//    public func set<Value>(_ fieldName: String, to value: Value)
//        where Value: Codable
//    {
//        self.storage.set(fieldName, to: value)
//    }
//}
