protocol Storage {
    var output: DatabaseOutput? { get }
    var cachedOutput: [String: Any] { get set }
    var input: [String: DatabaseQuery.Value] { get set }
    var eagerLoads: [String: EagerLoad] { get set }
    var exists: Bool { get set }
    var path: [String] { get }
}

struct DefaultStorage: Storage {
    static let empty: DefaultStorage = .init(
        output: nil,
        eagerLoads: [:],
        exists: false
    )
    
    var output: DatabaseOutput?
    var cachedOutput: [String : Any]
    var input: [String: DatabaseQuery.Value]
    var eagerLoads: [String: EagerLoad]
    var exists: Bool
    var path: [String] {
        return []
    }

    init(output: DatabaseOutput?, eagerLoads: [String: EagerLoad], exists: Bool) {
        self.output = output
        self.cachedOutput = [:]
        self.eagerLoads = eagerLoads
        self.input = [:]
        self.exists = exists
    }
}

extension Storage {
    mutating func cacheOutput<Model>(for model: Model.Type) throws
        where Model: FluentKit.Model
    {
        for property in Model.shared.fields {
            self.cachedOutput[property.name] = try property.cached(from: self.output!)
        }
    }

    public func get<Value>(_ name: String, as value: Value.Type = Value.self) -> Value
        where Value: Codable
    {
        if let input = self.input[name] {
            switch input {
            case .bind(let encodable): return encodable as! Value
            default: fatalError("Non-matching input.")
            }
        } else if let output = self.cachedOutput[name] {
            return output as! Value
        } else {
            fatalError("\(name) was not selected.")
        }
    }
    public mutating func set<Value>(_ name: String, to value: Value)
        where Value: Codable
    {
        self.input[name] = .bind(value)
    }
}
