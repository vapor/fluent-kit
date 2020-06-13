public protocol Migration {
    var name: String { get }
    func prepare(on database: Database) -> EventLoopFuture<Void>
    func revert(on database: Database) -> EventLoopFuture<Void>
}

extension Migration {
    public var name: String {
        return defaultName
    }

    internal var defaultName: String {
        return String(reflecting: Self.self)
    }
}
