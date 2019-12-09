@propertyWrapper
public final class Parent<To> where To: ParentRelatable {
    internal var eagerLoadedValue: EagerLoaded
    internal var eagerLoadRequest: EagerLoadRequest
    @Field public var id: To.StoredIDValue

    public var wrappedValue: To {
        get {
            switch self.eagerLoadedValue {
            case .notLoaded: fatalError("Parent relation not eager loaded, use $ prefix to access")
            case let .loaded(value): return value
            }
        }
        set {
            fatalError("use $ prefix to access")
        }
    }

    public var projectedValue: Parent<To> { self }

    private init(id: String, eagerLoadRequest: EagerLoadRequest) {
        self.eagerLoadedValue = .notLoaded
        self.eagerLoadRequest = eagerLoadRequest
        self._id = Field(key: id)
    }
}

extension Parent {
    public enum EagerLoaded: CustomStringConvertible {
        case loaded(To)
        case notLoaded

        public var description: String {
            switch self {
            case let .loaded(model): return "loaded(\(model.description))"
            case .notLoaded: return "notLoaded"
            }
        }
    }
}

extension Parent: FieldRepresentable {
    public var field: Field<To.StoredIDValue> { self.$id }
}

extension Parent: AnyProperty {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if case let .loaded(parent) = self.eagerLoadedValue {
            try container.encode(parent)
        } else {
            try container.encode([self.$id.key: self.id])
        }
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .string(self.$id.key)))
        // TODO: allow for nested decoding
    }
}

extension Parent: AnyField { }


// MARK: - Specialization

extension Parent where To: Model {
    public convenience init(key: String) {
        self.init(id: key, eagerLoadRequest: SubqueryEagerLoad(key: key))
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database).filter(\._$id == self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.query(on: database).first().flatMapThrowing { parent in
            guard let parent = parent else {
                throw FluentError.missingParent
            }
            return parent
        }
    }
}

extension Parent where To: OptionalType, To.Wrapped: Model, To.StoredIDValue == To.Wrapped.IDValue? {
    public convenience init(key: String) {
        self.init(id: key, eagerLoadRequest: SubqueryEagerLoad(key: key))
    }

    public func query(on database: Database) -> QueryBuilder<To.Wrapped> {
        return To.Wrapped.query(on: database).filter(\To.Wrapped._$id == self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.query(on: database).first().flatMapThrowing { parent in parent as! To }
    }
}


// MARK: - Optionals

public protocol ParentRelatable: Codable, CustomStringConvertible {
    associatedtype StoredIDValue: Codable, Hashable

    static func defaultEagerLoaded(for id: StoredIDValue) -> Parent<Self>.EagerLoaded

    var storedID: StoredIDValue { get }
}


extension Optional: ParentRelatable, CustomStringConvertible where Wrapped: Model {
    public typealias StoredIDValue = Wrapped.IDValue?

    public var description: String { (self?.description).map { "Optional(\($0))" } ?? "nil" }
    public var storedID: Wrapped.IDValue? { self?.id }

    public static func defaultEagerLoaded(for id: StoredIDValue) -> Parent<Self>.EagerLoaded {
        return id.map { _ in .notLoaded } ?? .loaded(nil)
    }
}

extension Model {
    public var storedID: StoredIDValue { self.id! }

    public static func defaultEagerLoaded(for id: StoredIDValue) -> Parent<Self>.EagerLoaded { .notLoaded }
}

