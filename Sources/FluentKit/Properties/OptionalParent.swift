@propertyWrapper
public final class OptionalParent<To>
    where To: Model
{
    @Field
    public var id: To.IDValue?

    public var wrappedValue: To? {
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

    var eagerLoadedValue: To?
    var didEagerLoad: Bool

    public init(key: String) {
        self._id = .init(key: key)
        self.didEagerLoad = false
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database)
            .filter(\._$id == self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To?> {
        return self.query(on: database).first()
    }
}

extension OptionalParent: FieldRepresentable {
    public var field: Field<To.IDValue?> {
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
                To.key(for: \._$id): self.id
            ])
        }
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .string(To.key(for: \._$id))))
        // TODO: allow for nested decoding
    }
}

extension OptionalParent: AnyField { }
