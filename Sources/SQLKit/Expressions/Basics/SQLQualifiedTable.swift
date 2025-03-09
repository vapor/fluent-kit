/// An expression representing an optionally second-level-qualified SQL table.
///
/// The meaning of a second-level qualification as applied to a table is dependent on the underlying database.
/// In PostgreSQL, a table reference is typically qualified with a schema; in MySQL or SQLite, a qualified table
/// reference refers to an alternate database.
public struct SQLQualifiedTable<TableExpr: SQLExpression, SpaceExpr: SQLExpression>: SQLExpression {
    /// The table name, usually an ``SQLObjectIdentifier``.
    public var table: TableExpr

    /// If specified, the second-level namespace to which the table belongs.
    /// Usually an ``SQLObjectIdentifier`` if not `nil`.
    public var space: SpaceExpr?

    /// Create an ``SQLQualifiedTable`` from a name and optional second-level namespace.
    public init(_ table: String, space: String? = nil) where TableExpr == SQLObjectIdentifier, SpaceExpr == SQLObjectIdentifier {
        self.init(SQLObjectIdentifier(table), space: space.flatMap(SQLObjectIdentifier.init(_:)))
    }
    
    /// Create an ``SQLQualifiedTable`` from an identifier and optional second-level identifier.
    public init(_ table: TableExpr, space: SpaceExpr? = nil) {
        self.table = table
        self.space = space
    }
    
    // See `SQLExpression.serialize(to:)`.
    public func serialize(to serializer: inout SQLSerializer) {
        if let space = self.space {
            space.serialize(to: &serializer)
            serializer.write(".")
        }
        self.table.serialize(to: &serializer)
    }
}
