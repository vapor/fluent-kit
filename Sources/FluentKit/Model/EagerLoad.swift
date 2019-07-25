protocol EagerLoadRequest: class, CustomStringConvertible {
    func prepare(_ query: inout DatabaseQuery)
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
}

final class EagerLoadStorage: CustomStringConvertible {
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
