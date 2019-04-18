#warning("TODO: make protocol internal")
public protocol ModelStorage {
    var output: DatabaseOutput? { get }
    var input: [String: DatabaseQuery.Value] { get set }
    var eagerLoads: [String: EagerLoad] { get set }
    var exists: Bool { get set }
    var path: [String] { get }
}

struct DefaultModelStorage: ModelStorage {
    static let empty: DefaultModelStorage = .init(
        output: nil,
        eagerLoads: [:],
        exists: false
    )
    
    var output: DatabaseOutput?
    var input: [String: DatabaseQuery.Value]
    var eagerLoads: [String: EagerLoad]
    var exists: Bool
    var path: [String] {
        return []
    }

    init(output: DatabaseOutput?, eagerLoads: [String: EagerLoad], exists: Bool) {
        self.output = output
        self.eagerLoads = eagerLoads
        self.input = [:]
        self.exists = exists
    }
}
