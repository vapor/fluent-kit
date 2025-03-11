/// A fundamental syntactical expression - a list of subexpresions with a specified "separator" subexpression.
///
/// When serialized, an empty ``SQLList`` outputs nothing, a single-item ``SQLList`` outputs the serialization of
/// that one expression, and all other ``SQLList``s output the entire list of subexpressions joined by an appropriate
/// number of copies of the separator subexpression. The default separator is `SQLUnsafeRaw(", ")`.
///
/// Examples:
///
/// ```swift
/// print(database.serialize(SQLList(SQLLiteral.string("a"), SQLLiteral.string("b"))).sql)
/// // "'a', 'b'"
/// print(database.serialize(SQLList(SQLLiteral.string("a"), SQLLiteral.string("b"), separator: SQLBinaryOperator.and)).sql)
/// // "'a'AND'b'"
/// print(database.serialize(SQLList(SQLLiteral.string("a"), SQLLiteral.string("b"), separator: SQLUnsafeRaw(" AND ")).sql)
/// // "'a' AND 'b'"
/// ```
public struct SQLList: SQLExpression {
    /// The list of subexpressions to join.
    public var expressions: [any SQLExpression]

    /// The string with which to join the list of subexpressions.
    public var separator: String

    /// Create a list from a list of expressions and an optional separator.
    ///
    /// - Parameters:
    ///   - expressions: The list of expressions.
    ///   - separator: A separator. If not given, defaults to `", "`.
    @inlinable
    public init(_ expressions: [any SQLExpression], separator: some StringProtocol = String(", ")) {
        self.expressions = expressions
        self.separator = String(separator)
    }

    // See `SQLExpression.serialize(to:)`.
    public func serialize(to serializer: inout SQLSerializer) {
        var iter = self.expressions.makeIterator()

        iter.next()?.serialize(to: &serializer)
        while let item = iter.next() {
            serializer.write(self.separator)
            item.serialize(to: &serializer)
        }
    }
}
