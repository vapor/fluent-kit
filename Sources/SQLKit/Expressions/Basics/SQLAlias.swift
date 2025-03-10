///  Encapsulates SQL's `<expression> [AS] <name>` syntax, most often used to declare aliaed names
///  for columns and tables.
public struct SQLAlias: SQLExpression {
    /// The ``SQLExpression`` to alias.
    public var expression: any SQLExpression
    
    /// The alias itself.
    public var alias: any SQLExpression
    
    /// Create an alias expression from an expression and an alias expression.
    ///
    /// - Parameters:
    ///   - expression: The expression to alias.
    ///   - alias: The alias itself.
    @inlinable
    public init(_ expression: any SQLExpression, as alias: any SQLExpression) {
        self.expression = expression
        self.alias = alias
    }
    
    /// Create an alias expression from an expression and an alias name.
    ///
    /// - Parameters:
    ///   - expression: The expression to alias.
    ///   - alias: The aliased name.
    @inlinable
    public init(_ expression: any SQLExpression, as alias: some StringProtocol) {
        self.init(expression, as: SQLObjectIdentifier(alias))
    }

    /// Create an alias expression from a name and an alias name.
    ///
    /// - Parameters:
    ///   - name: The name to alias.
    ///   - alias: The aliased name.
    @inlinable
    public init(_ name: some StringProtocol, as alias: some StringProtocol) {
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
