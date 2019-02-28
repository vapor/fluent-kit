public protocol NestedModel: AnyModel { }

extension AnyModel {
    public func nested<Nested>(
        _ name: String,
        _ dataType: DatabaseSchema.DataType? = nil,
        _ constraints: DatabaseSchema.FieldConstraint...
    ) -> Nested
        where Nested: AnyModel
    {
        let storage = NestedModelStorage(
            name: name,
            base: self,
            dataType: dataType,
            constraints: constraints
        )
        return .init(storage: storage)
    }
}

extension NestedModel {
    public var property: ModelProperty {
        return NestedProperty(entity: self)
    }
}

// MARK: Private

private struct NestedOutput: DatabaseOutput {
    let name: String
    let base: DatabaseOutput
    init(name: String, _ base: DatabaseOutput) {
        self.name = name
        self.base = base
    }
    
    var description: String {
        return self.base.description
    }
    
    func decode<T>(field: String, as type: T.Type) throws -> T where T: Decodable {
        let base = try self.base.decode(
            field: self.name,
            as: DecoderUnwrapper.self
        )
        let decoder = try base.decoder.container(keyedBy: StringCodingKey.self)
        return try decoder.decode(T.self, forKey: .init(field))
    }
}

private struct NestedModelStorage: ModelStorage {
    let name: String
    let base: AnyModel
    let dataType: DatabaseSchema.DataType?
    let constraints: [DatabaseSchema.FieldConstraint]
    
    var path: [String] {
        return self.base.storage.path + [self.name]
    }
    
    var output: DatabaseOutput? {
        return self.base.storage.output.flatMap { output in
            return NestedOutput(name: self.name, output)
        }
    }
    
    var input: [String: DatabaseQuery.Value] {
        get {
            switch self.base.storage.input[self.name] {
            case .none: return [:]
            case .some(let some):
                switch some {
                case .dictionary(let dict): return dict
                default: return [:]
                }
            }
        }
        set { self.base.storage.input[self.name] = .dictionary(newValue) }
    }
    
    var eagerLoads: [String: EagerLoad] {
        get { return self.base.storage.eagerLoads }
        set { self.base.storage.eagerLoads = newValue }
    }
    
    var exists: Bool {
        get { return self.base.storage.exists }
        set { self.base.storage.exists = newValue }
    }
}

private struct NestedProperty<Nested>: ModelProperty
    where Nested: NestedModel
{
    let entity: Nested
    
    init(entity: Nested) {
        self.entity = entity
    }
    
    public var name: String {
        guard let storage = self.entity.storage as? NestedModelStorage else {
            fatalError()
        }
        return storage.name
    }
    
    var dataType: DatabaseSchema.DataType? {
        guard let storage = self.entity.storage as? NestedModelStorage else {
            fatalError()
        }
        return storage.dataType
    }
    
    var constraints: [DatabaseSchema.FieldConstraint] {
        guard let storage = self.entity.storage as? NestedModelStorage else {
            fatalError()
        }
        return storage.constraints
    }
    
    public var type: Any.Type {
        return Nested.self
    }
    
    func encode(to encoder: inout ModelEncoder) throws {
        try encoder.encode(self.entity, forKey: self.name)
    }
    
    func decode(from decoder: ModelDecoder) throws {
        let model = try decoder.decode(Nested.self, forKey: self.name)
        self.entity.storage = model.storage
    }
}
