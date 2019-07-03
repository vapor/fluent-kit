protocol EagerLoadRequest: class {
    func prepare(_ query: inout DatabaseQuery)
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
}

final class EagerLoadStorage {
    var requests: [String: EagerLoadRequest]
    init() {
        self.requests = [:]
    }
}

public enum EagerLoadMethod {
    case subquery
    case join
}
