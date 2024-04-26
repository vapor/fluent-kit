import struct NIOConcurrencyHelpers.NIOLockedValueBox

/// Holds the history of queries for a database.
public final class QueryHistory: @unchecked Sendable {
    /// The underlying (locked) storage.
    private let _queries: NIOLockedValueBox<[DatabaseQuery]> = .init([])
    
    /// The queries that have been executed.
    ///
    /// > Warning: This array can be modified aribtrarily by any code with access to the ``QueryHistory``
    /// > object; there is no guarantee that it represents a consistent and accurate history. This is an
    /// > accidental design flaw that can't be changed now without breaking the API.
    public var queries: [DatabaseQuery] {
        get { self._queries.withLockedValue { $0 } }
        set { self._queries.withLockedValue { $0 = newValue } }
    }

    /// Create a new ``QueryHistory`` with no existing history.
    public init() {}
    
    /// Add a query to the history.
    func add(_ query: DatabaseQuery) {
        self._queries.withLockedValue { $0.append(query) }
    }
}
