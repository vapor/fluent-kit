/// Encapsulates a `column_name=value` expression in the context of an `UPDATE` query's value
/// assignment list. This is distinct from an ``SQLBinaryExpression`` using the `.equal`
/// operator in that the left side must be an _unqualified_ column name, the operator must
/// be `=`, and the right side may use ``SQLExcludedColumn`` when the assignment appears in
/// the `assignments` list of a ``SQLConflictAction/update(assignments:predicate:)`` specification.
public struct SQLColumnAssignment<ColExpr: SQLExpression, ValueExpr: SQLExpression>: SQLExpression {
    /// The name of the column to assign.
    public var columnName: ColExpr

    /// The value to assign.
    public var value: ValueExpr

    /// Create a column assignment from a column identifier and value expression.
    @inlinable
    public init(setting columnName: ColExpr, to value: ValueExpr) {
        self.columnName = columnName
        self.value = value
    }
    
    /// Create a column assignment from a column identifier and value binding.
    @inlinable
    public init(setting columnName: ColExpr, to value: any Encodable & Sendable) where ValueExpr == SQLBind {
        self.init(setting: columnName, to: SQLBind(value))
    }

    /// Create a column assignment from a column name and value binding.
    @inlinable
    public init(setting columnName: String, to value: any Encodable & Sendable) where ColExpr == SQLColumn<SQLObjectIdentifier, SQLObjectIdentifier>, ValueExpr == SQLBind {
        self.init(setting: columnName, to: SQLBind(value))
    }

    /// Create a column assignment from a column name and value expression.
    @inlinable
    public init(setting columnName: String, to value: ValueExpr) where ColExpr == SQLColumn<SQLObjectIdentifier, SQLObjectIdentifier> {
        self.init(setting: SQLColumn(columnName), to: value)
    }
    
    /// Create a column assignment from a column name and using the excluded value
    /// from an upsert's values list.
    ///
    /// See ``SQLExcludedColumn`` for additional details about excluded values.
    @inlinable
    public init(settingExcludedValueFor columnName: String) where ColExpr == SQLColumn<SQLObjectIdentifier, SQLObjectIdentifier>, ValueExpr == SQLExcludedColumn {
        self.init(settingExcludedValueFor: SQLColumn(columnName))
    }

    /// Create a column assignment from a column identifier and using the excluded value
    /// from an upsert's values list.
    ///
    /// See ``SQLExcludedColumn`` for additional details about excluded values.
    @inlinable
    public init(settingExcludedValueFor column: ColExpr) where ValueExpr == SQLExcludedColumn {
        self.init(setting: column, to: SQLExcludedColumn(column))
    }
    
    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            /// N.B.: Do not use SQLBinaryOperator.equal here; it can vary between dialects
            $0.append(self.columnName, "=", self.value)
        }
    }
}
