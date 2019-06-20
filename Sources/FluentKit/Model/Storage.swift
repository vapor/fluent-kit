protocol Storage {
    var output: DatabaseOutput? { get }
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
    var eagerLoads: [String: EagerLoad]
    var exists: Bool
    var path: [String] {
        return []
    }

    init(output: DatabaseOutput?, eagerLoads: [String: EagerLoad], exists: Bool) {
        self.output = output
        self.eagerLoads = eagerLoads
        self.exists = exists
    }
}
