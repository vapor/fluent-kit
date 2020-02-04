public protocol Relation {
    associatedtype RelatedValue

    var name: String { get }
    var value: RelatedValue? { get set }

    func load(on database: Database) -> EventLoopFuture<Void>
}

extension Relation {
    public func get(reload: Bool = false, on database: Database) -> EventLoopFuture<RelatedValue> {
        if let value = self.value, !reload {
            return database.eventLoop.makeSucceededFuture(value)
        } else {
            return self.load(on: database).flatMapThrowing {
                guard let value = self.value else {
                    throw FluentError.relationNotLoaded(name: self.name)
                }
                return value
            }
        }
    }
}
