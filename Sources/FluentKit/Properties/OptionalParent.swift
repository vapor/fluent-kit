@propertyWrapper
public final class OptionalParent<To>
    where To: Model
{
    @Field
    public var id: To.IDValue?

    public var wrappedValue: To? {
        get {
            self.value
        }
        set {
            fatalError("OptionalParent relation is get-only.")
        }
    }

    public var projectedValue: OptionalParent<To> {
        return self
    }

    public var value: To?

    public init(key: String) {
        self._id = .init(key: key)
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database)
            .filter(\._$id == self.id)
    }
}

extension OptionalParent: Relation {
    public var name: String {
        "OptionalParent<\(To.self)>(key: \(self.key))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).first().map {
            self.value = $0
        }
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
        if let parent = self.value {
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
