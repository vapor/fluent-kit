@propertyWrapper
public final class OptionalParent<To>
    where To: OptionalType, To.Wrapped: Model
{
    @Field
    public var id: To.Wrapped.IDValue?

    public var wrappedValue: To.Wrapped? {
        get {
            guard self.didEagerLoad else {
                fatalError("Optional parent relation not eager loaded, use $ prefix to access")
            }
            return self.eagerLoadedValue
        }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: OptionalParent<To> {
        return self
    }

    var eagerLoadedValue: To.Wrapped?
    var didEagerLoad: Bool

    public init(key: String) {
        self._id = .init(key: key)
        self.didEagerLoad = false
    }

    public func query(on database: Database) -> QueryBuilder<To.Wrapped> {
        return To.Wrapped.query(on: database)
            .filter(\._$id == self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To.Wrapped?> {
        return self.query(on: database).first()
    }

}

extension OptionalParent: FieldRepresentable {
    public var field: Field<To.Wrapped.IDValue?> {
        return self.$id
    }
}

extension OptionalParent: AnyProperty {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let parent = self.eagerLoadedValue {
            try container.encode(parent)
        } else {
            try container.encode([
                To.Wrapped.key(for: \._$id): self.id
            ])
        }
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .string(To.Wrapped.key(for: \._$id))))
        // TODO: allow for nested decoding
    }
}

extension OptionalParent: AnyField { }
