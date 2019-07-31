protocol EagerLoadRequest: class, CustomStringConvertible {
    func prepare(query: inout DatabaseQuery)
    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void>
}

final class EagerLoads: CustomStringConvertible {
    var requests: [String: EagerLoadRequest]

    var description: String {
        return self.requests.description
    }

    init() {
        self.requests = [:]
    }
}

public enum EagerLoadMethod {
    case subquery
    case join
}
