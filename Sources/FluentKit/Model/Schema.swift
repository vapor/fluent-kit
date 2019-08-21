public protocol AnySchema: class, Codable {
    init()
}

public protocol Schema: AnySchema {
    associatedtype IDValue: Codable, Hashable

    var id: IDValue? { get set }
}

extension AnySchema {
    // MARK: Codable

    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.properties.forEach { label, property in
            let decoder = try container.superDecoder(forKey: .string(label))
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: _ModelCodingKey.self)
        try self.properties.forEach { label, property in
            let encoder = container.superEncoder(forKey: .string(label))
            try property.encode(to: encoder)
        }
    }
}

extension Schema {
    static func key<Field>(for field: KeyPath<Self, Field>) -> String
        where Field: Filterable
    {
        return Self.init()[keyPath: field].key
    }
}

extension Schema {
    var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }

    @available(*, deprecated, message: "use init")
    static var reference: Self {
        return self.init()
    }
}

extension AnySchema {
    var anyID: AnyID {
        guard let id = Mirror(reflecting: self).descendant("_id") else {
            fatalError("id property must be declared using @ID")
        }
        return id as! AnyID
    }
}

extension Schema {
    public func requireID() throws -> IDValue {
        guard let id = self.id else {
            throw FluentError.idRequired
        }
        return id
    }
}
