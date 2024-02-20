import struct NIOConcurrencyHelpers.NIOLock

/// Holds the history of queries for a database
public final class QueryHistory {
    /// The queries that were executed over a period of time
    public var queries: [DatabaseQuery]

    /// Protects
    private var lock: NIOLock

    /// Create a new `QueryHistory` with no existing history
    public init() {
        self.queries = []
        self.lock = .init()
    }

    func add(_ query: DatabaseQuery) {
        self.lock.lock()
        defer { self.lock.unlock() }
        queries.append(query)
    }
}
