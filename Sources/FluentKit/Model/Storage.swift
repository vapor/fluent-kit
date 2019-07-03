protocol Storage {
    var output: DatabaseOutput? { get }
    var eagerLoadStorage: EagerLoadStorage { get set }
    var exists: Bool { get set }
    var path: [String] { get }
}

struct DefaultStorage: Storage {
    static let empty: DefaultStorage = .init(
        output: nil,
        eagerLoadStorage: .init(),
        exists: false
    )
    
    var output: DatabaseOutput?
    var eagerLoadStorage: EagerLoadStorage
    var exists: Bool
    var path: [String] {
        return []
    }

    init(output: DatabaseOutput?, eagerLoadStorage: EagerLoadStorage, exists: Bool) {
        self.output = output
        self.eagerLoadStorage = eagerLoadStorage
        self.exists = exists
    }
}
