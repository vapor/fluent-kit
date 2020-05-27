/// Holds the history of queries for a database
public final class QueryHistory {

    /// The queries that were executed over a period of time
    public var queries: [DatabaseQuery]

    /// Create a new `QueryHistory` with no existing history
    public convenience init() {
        self.init(queries: [])
    }

    /// Create a new `QueryHistory` object
    /// - Parameter queries: The queries
    public init(queries: [DatabaseQuery]) {
        self.queries = queries
    }

    func add(_ query: DatabaseQuery) {
        queries.append(query)
    }
}
