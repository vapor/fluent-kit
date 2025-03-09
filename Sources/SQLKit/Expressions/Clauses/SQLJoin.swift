/// Encapsulates a single SQL `JOIN`, specifying the join type, the right-side table, and condition.
///
/// This expression does _not_ include the left side of the join, as individual join clauses are more naturally
/// syntactically treated as starting at the join method; additionally, this simplifies the expressing joins where the
/// left side is part of a `FROM` or other non-join clause.
///
/// See ``SQLJoinBuilder``.
public struct SQLJoin<MethodExpr: SQLExpression, TableExpr: SQLExpression, CondExpr: SQLExpression>: SQLExpression {
    /// The join method.
    ///
    /// See ``SQLJoinMethod``.
    public var method: MethodExpr

    /// The table with which to join.
    public var table: TableExpr

    /// The join condition.
    public var expression: CondExpr

    /// Create a new `SQLJoin`.
    ///
    /// - Parameters:
    ///   - method: The join method.
    ///   - table: The table to join.
    ///   - expression: The join condition.
    @inlinable
    public init(method: MethodExpr, table: TableExpr, expression: CondExpr) {
        self.method = method
        self.table = table
        self.expression = expression
    }

    // See `SQLExpression.serialize(to:)`.
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            $0.append(self.method, "JOIN")
            $0.append(self.table, "ON", self.expression)
        }
    }
}
