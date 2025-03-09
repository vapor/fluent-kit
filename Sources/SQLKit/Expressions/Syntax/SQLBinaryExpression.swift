/// A fundamental syntactical expression - a left and right operand joined by an infix operator.
///
/// This construct forms the basis of most comparisons, conditionals, and compounds which can be
/// represented by an expression.
///
/// For example, the expression `foo = 1 AND bar <> 'baz' OR bop - 5 NOT IN (1, 3)` can be represented
/// in terms of nested ``SQLBinaryExpression``s (note that there is more than one "correct" way to nest
/// this particular example):
///
/// ```swift
/// let expr = SQLBinaryExpression(
///     SQLBinaryExpression(SQLColumn("foo"), .equal, SQLLiteral.numeric("1")),
///     .and,
///     SQLBinaryExpression(
///         SQLBinaryExpression(SQLColumn("bar"), .notEqual, SQLLiteral.string("baz")),
///         .or,
///         SQLBinaryExpression(
///             SQLBinaryExpression(SQLColumn("bop"), .subtract, SQLLiteral.numeric("5")),
///             .notIn,
///             SQLGroupExpression(SQLLiteral.numeric("1"), SQLLiteral.numeric("3"))
///         )
///     )
/// )
/// ```
public struct SQLBinaryExpression<LeftExpr: SQLExpression, OperExpr: SQLExpression, RightExpr: SQLExpression>: SQLExpression {
    /// The left-side operand of the expression.
    public let left: LeftExpr

    /// The operator joining the left and right operands.
    public let op: OperExpr

    /// The right-side operand of the expression.
    public let right: RightExpr

    /// Create an ``SQLBinaryExpression`` from component expressions.
    ///
    /// - Parameters:
    ///   - left: The left-side oeprand.
    ///   - op: The operator.
    ///   - right: The right-side operand.
    @inlinable
    public init(
        left: LeftExpr,
        op: OperExpr,
        right: RightExpr
    ) {
        self.left = left
        self.op = op
        self.right = right
    }
    
    /// Create an ``SQLBinaryExpression`` from two operand expressions and a predefined binary operator.
    ///
    /// - Parameters:
    ///   - left: The left-side operand.
    ///   - op: The binary operator.
    ///   - right: The right-side operand.
    @inlinable
    public init(
        _ left: LeftExpr,
        _ op: SQLBinaryOperator,
        _ right: RightExpr
    ) where OperExpr == SQLBinaryOperator {
        self.init(left: left, op: op, right: right)
    }

    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            $0.append(self.left)
            $0.append(self.op)
            $0.append(self.right)
        }
    }
}
