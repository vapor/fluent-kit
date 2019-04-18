public struct ModelParent<Child, Parent>: ModelProperty
    where Parent: Model, Child: Model
{
    public var type: Any.Type {
        return Parent.ID.self
    }

    internal enum Storage {
        case none
        case id(Parent.ID)
        case eagerLoaded(Parent)
        case input(Parent.ID)
    }

    public var id: ModelField<Child, Parent.ID> {
        get {
            switch self.storage {
            case .none:
                fatalError()
            case .id(let id):
                return .init(value: id)
            case .eagerLoaded(let parent):
                return .init(value: parent.id.value)
            case .input(let id):
                return .init(value: id)
            }
        }
        set {
            self.storage = .input(newValue.value)
        }
    }

    var storage: Storage

    public init() {
        self.storage = .none
    }

    public var input: Encodable? {
        switch self.storage {
        case .input(let id):
            return id
        default:
            return nil
        }
    }
    
    public func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
//        if let cache = storage.eagerLoads[Parent.entity] {
//            let parent = try cache.get(id: storage.get("foo", as: Parent.ID.self))
//                .map { $0 as! Parent }
//                .first!
//            try encoder.encode(parent, forKey: ")
//        }
        switch self.storage {
        case .none: break
        case .id(let id):
            try encoder.encode(id, forKey: "parentID")
        case .eagerLoaded(let parent):
            try encoder.encode(parent, forKey: "\(Parent.self)".lowercased())
        case .input(let id):
            try encoder.encode(id, forKey: "parentID")
        }
    }
    
    public func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        fatalError()
        // try self.id.decode(from: decoder, to: &storage)
    }

    public func get() -> Parent {
        switch self.storage {
        case .eagerLoaded(let parent):
            return parent
        default:
            fatalError("No cache set on storage.")
        }
    }
}

extension Model {
    public typealias Parent<ParentType> = ModelParent<Self, ParentType>
        where ParentType: Model
    
    public typealias ParentKey<ParentType> = KeyPath<Self, Parent<ParentType>>
        where ParentType: Model
    
    public func parent<T>(forKey key: ParentKey<T>) -> Parent<T> {
        return self[keyPath: key]
    }
}

//
//extension ModelParent: ModelProperty {
//    public var name: String {
//        return self.id.name
//    }
//
//    public var type: Any.Type {
//        return self.id.type
//    }
//
//    public var dataType: DatabaseSchema.DataType? {
//        return self.id.dataType
//    }
//
//    public var constraints: [DatabaseSchema.FieldConstraint] {
//        return self.id.constraints
//    }
//
//    public func encode(to encoder: inout ModelEncoder) throws {

//    }
//
//    public func decode(from decoder: ModelDecoder) throws {
//        try self.id.decode(from: decoder)
//    }
//}

