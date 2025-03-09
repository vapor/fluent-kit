///  Encapsulates SQL's `<expression> [AS] <name>` syntax, most often used to declare aliaed names
///  for columns and tables.
public struct SQLAlias<Expr: SQLExpression, AliasExpr: SQLExpression>: SQLExpression {
    /// The ``SQLExpression`` to alias.
    public let expression: Expr

    /// The alias itself.
    public let alias: AliasExpr

    /// Create an alias expression from an expression and an alias expression.
    ///
    /// - Parameters:
    ///   - expression: The expression to alias.
    ///   - alias: The alias itself.
    @inlinable
    public init(_ expression: Expr, as alias: AliasExpr) {
        self.expression = expression
        self.alias = alias
    }
    
    /// Create an alias expression from an expression and an alias name.
    ///
    /// - Parameters:
    ///   - expression: The expression to alias.
    ///   - alias: The aliased name.
    @inlinable
    public init(_ expression: Expr, as alias: String) where AliasExpr == SQLObjectIdentifier {
        self.init(expression, as: SQLObjectIdentifier(alias))
    }

    /// Create an alias expression from a name and an alias name.
    ///
    /// - Parameters:
    ///   - name: The name to alias.
    ///   - alias: The aliased name.
    @inlinable
    public init(_ name: String, as alias: String) where Expr == SQLObjectIdentifier, AliasExpr == SQLObjectIdentifier {
        self.init(SQLObjectIdentifier(name), as: SQLObjectIdentifier(alias))
    }

    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            $0.append(self.expression)
            $0.append("AS", self.alias)
        }
    }
}
