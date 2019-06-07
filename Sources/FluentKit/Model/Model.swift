public protocol AnyModel: class {
    static var name: String { get }
    static var entity: String { get }
    static var id: String { get }
}

public protocol Model: AnyModel {
    associatedtype ID: Codable, Hashable
    var id: ID? { get set }

    init()

    // MARK: Lifecycle

    func willCreate(on database: Database) -> EventLoopFuture<Void>
    func didCreate(on database: Database) -> EventLoopFuture<Void>

    func willUpdate(on database: Database) -> EventLoopFuture<Void>
    func didUpdate(on database: Database) -> EventLoopFuture<Void>

    func willDelete(on database: Database) -> EventLoopFuture<Void>
    func didDelete(on database: Database) -> EventLoopFuture<Void>

    func willRestore(on database: Database) -> EventLoopFuture<Void>
    func didRestore(on database: Database) -> EventLoopFuture<Void>

    func willSoftDelete(on database: Database) -> EventLoopFuture<Void>
    func didSoftDelete(on database: Database) -> EventLoopFuture<Void>
}

extension AnyModel {
    public static var name: String {
        return "\(Self.self)".lowercased()
    }

    public static var entity: String {
        return self.name + "s"
    }
}

// MARK: Reflection

public protocol AnyReflectable {
    static var anyReflectionValue: Any { get }
}

public protocol Reflectable: AnyReflectable {
    static var reflectionValue: Self { get }
}

extension Reflectable {
    public static var anyReflectionValue: Any {
        return self.reflectionValue
    }
}

extension String: Reflectable {
    public static var reflectionValue: String {
        return ""
    }
}

extension Int: Reflectable {
    public static var reflectionValue: Int {
        return 0
    }
}

extension Optional: AnyReflectable where Wrapped: AnyReflectable {
    public static var anyReflectionValue: Any {
        return Wrapped.anyReflectionValue
    }
}

extension Optional: Reflectable where Wrapped: Reflectable {
    public static var reflectionValue: Optional<Wrapped> {
        return Wrapped.reflectionValue
    }
}

extension Date: Reflectable {
    public static var reflectionValue: Date {
        return .init(timeIntervalSince1970: 0)
    }
}


internal final class ReflectionContext {
    var lastAccessedField: AnyField?
}

protocol AnyProperty: class {
    var storage: Storage? { get }
    var type: Any.Type { get }
    var name: String { get }
    
    func initialize(label: String)
    func initialize(reflectionContext: ReflectionContext)
    func initialize(storage: Storage) throws

    func encode(to encoder: inout ModelEncoder) throws
    func decode(from decoder: ModelDecoder) throws
}

protocol AnyField: AnyProperty {
    var input: DatabaseQuery.Value? { get }
    var dataType: DatabaseSchema.DataType? { get }
    var constraints: [DatabaseSchema.FieldConstraint] { get }
}

extension Model {
    static func reflectable() -> (Self, ReflectionContext) {
        let new = self.reference()
        let reflectionContext = ReflectionContext()
        new.fields.forEach { field in
            field.initialize(reflectionContext: reflectionContext)
        }
        return (new, reflectionContext)
    }

    static func reference() -> Self {
        let new = Self.init()
        new.initializeLabels()
        return new
    }
    
    func initializeLabels() {
        for child in Mirror(reflecting: self).children {
            if let field = child.value as? AnyField, let label = child.label {
                field.initialize(label: String(label.dropFirst()))
            }
        }
    }

    var fields: [AnyField] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? AnyField }
    }

    var properties: [AnyProperty] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? AnyProperty }
    }

    static func field<T>(for keyPath: KeyPath<Self, T>) -> AnyField {
        let (model, context) = Self.reflectable()
        _ = model[keyPath: keyPath]
        return context.lastAccessedField!
    }

    public static func name<T>(for keyPath: KeyPath<Self, T>) -> String {
        return self.field(for: keyPath).name
    }
}


extension Model {
    public static func find(_ id: Self.ID?, on database: Database) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database).filter(\.id == id).first()
    }

    public static var id: String {
        #warning("TODO: static id")
        return ""
        // return self.shared.id.name
    }

    var storage: Storage? {
        return self.fields.first!.storage
    }
}

extension Model {
    public func willCreate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didCreate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willUpdate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didUpdate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willRestore(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didRestore(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willSoftDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didSoftDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}


//extension Model {
//    public static func row() -> Row<Self> {
//        let new = Row<Self>()
//        if let timestampable = Self.shared as? _AnyTimestampable {
//            timestampable._initializeTimestampable(&new.storage.input)
//        }
//        if let softDeletable = Self.shared as? _AnySoftDeletable {
//            softDeletable._initializeSoftDeletable(&new.storage.input)
//        }
//        return new
//    }
//}

extension Model {
    public static func query(on database: Database) -> QueryBuilder<Self> {
        return .init(database: database)
    }
}

extension Array where Element: Model {
    public func create(on database: Database) -> EventLoopFuture<Void> {
        let builder = Element.query(on: database)
        self.forEach { model in
            precondition(!model.exists)
            builder.set(model.input)
        }
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { created in
            let next = it.next()!
            next.storage!.exists = true
        }
    }
}

extension Model {
    public var exists: Bool {
        return self.storage?.exists ?? false
    }

    init(storage: Storage) throws {
        self.init()
        try self.load(storage: storage)
    }

    func load(storage: Storage) throws {
        for field in self.fields {
            try field.initialize(storage: storage)
        }
    }

    var input: [String: DatabaseQuery.Value] {
        var input: [String: DatabaseQuery.Value] = [:]
        
        self.initializeLabels()
        for field in self.fields {
            input[field.name] = field.input
        }

        return input
    }

    public var description: String {
        let input: String
        if self.input.isEmpty {
            input = "nil"
        } else {
            input = self.input.description
        }
        let output: String
        if let o = self.storage?.output {
            output = o.description
        } else {
            output = "nil"
        }
        return "\(Self.self)(input: \(input), output: \(output))"
    }

    // MARK: Fields

    #warning("TODO: fix")

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

    // MARK: Join

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: FluentKit.Model
    {
        return try Joined(storage: DefaultStorage(
            output: self.storage!.output!.prefixed(by: Joined.entity + "_"),
            eagerLoads: [:],
            exists: true
        ))
    }

    //    // MARK: Parent
    //
    //    public subscript<Value>(dynamicMember field: KeyPath<Model, Parent<Value>>) -> RowParent<Value> {
    //        return RowParent(
    //            parent: Model.shared[keyPath: field],
    //            row: self
    //        )
    //    }
    //
    //    // MARK: Children
    //
    //    public subscript<Value>(dynamicMember field: KeyPath<Model, Children<Value>>) -> RowChildren<Value> {
    //        return RowChildren(
    //            children: Model.shared[keyPath: field],
    //            row: self
    //        )
    //    }
    //
    //    // MARK: Dynamic Member Lookup
    //
    //    public subscript<Value>(dynamicMember field: KeyPath<Model, Field<Value>>) -> Value {
    //        get {
    //            return self.get(field)
    //        }
    //        set {
    //            self.set(field, to: newValue)
    //        }
    //    }

    // MARK: Codable

    public init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        for property in Self.reference().properties {
            do {
                try property.decode(from: decoder)
            } catch {
                print("Could not decode \(property.name): \(error)")
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for property in Self.reference().properties {
            try property.encode(to: &encoder)
        }
    }
}
