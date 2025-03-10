/// A fundamental syntactical expression - an arbitrary string of raw SQL with no escaping or formating of any kind.
///
/// Users should almost never need to use ``SQLUnsafeRaw`` directly; there is almost always a better/safer/more
/// specific expression available for any given purpose. The most common use for ``SQLUnsafeRaw`` by end users is to
/// represent SQL keywords specific to a dialect, such as `SQLUnsafeRaw("EXPLAIN VERBOSE")`.
///
/// In effect, ``SQLUnsafeRaw`` is nothing but a wrapper which makes `String`s into ``SQLExpression``s, since
/// conforming `String` directly to the protocol would cause numerous issues with SQLKit's existing public API (yet
/// another design flaw).
public struct SQLUnsafeRaw: SQLExpression {
    /// The raw SQL text serialized by this expression.
    public var sql: String

    /// Create a new raw SQL text expression.
    ///
    /// - Parameter sql: The raw SQL text to serialize.
    @inlinable
    public init(_ sql: some StringProtocol) {
        self.sql = String(sql)
    }

    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write(self.sql)
    }
}
