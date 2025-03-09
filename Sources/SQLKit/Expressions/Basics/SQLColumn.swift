/// An expression representing an optionally table-qualified column in an SQL table.
public struct SQLColumn<NameExpr: SQLExpression, TableExpr: SQLExpression>: SQLExpression {
    /// The column name.
    ///
    /// Usually an ``SQLObjectIdentifier``.
    public var name: NameExpr

    /// If specified, the table to which the column belongs.
    ///
    /// Usually an ``SQLObjectIdentifier`` or ``SQLQualifiedTable`` when not `nil`.
    public var table: TableExpr?

    /// Create an ``SQLColumn`` from a name and optional table name.
    @inlinable
    public init(_ name: String, table: String? = nil) where NameExpr == SQLObjectIdentifier, TableExpr == SQLObjectIdentifier {
        self.init(SQLObjectIdentifier(name), table: table.flatMap(SQLObjectIdentifier.init(_:)))
    }
    
    /// Create an ``SQLColumn`` from an identifier and optional table expression.
    @inlinable
    public init(_ name: NameExpr, table: TableExpr? = nil) {
        self.name = name
        self.table = table
    }
    
    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        if let table = self.table {
            table.serialize(to: &serializer)
            serializer.write(".")
        }
        self.name.serialize(to: &serializer)
    }
}
