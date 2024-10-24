/// Column-level data constraints.
/// 
/// Most dialects of SQL support both column-level (specific to a single column) and table-level (applicable to a list
/// of one or more columns within the table) constraints. While some constraints can be expressed either way, others
/// are only allowed at the column level. See ``SQLTableConstraintAlgorithm`` for table-level constraints.
/// 
/// Column-level constraints typically do not have separate constraint names, and are thus not used in concert with
/// ``SQLConstraint`` expressions except in unusual cases.
/// 
/// Column constraints are used primarily by ``SQLColumnDefinition``, and also appear directly in the APIs of
/// ``SQLAlterTableBuilder``, ``SQLCreateIndexBuilder``, and ``SQLCreateTableBuilder``.
public enum SQLColumnConstraintAlgorithm: SQLExpression {
    /// A `PRIMARY KEY` constraint, either with or without the auto-increment characteristic.
    ///
    /// Different SQL dialects define and express auto-increment functionality in widely varying ways. For example,
    /// with SQLite, auto-increment determines the algorithm used for generating internal row identifiers, not whether
    /// or not values are autogenerated. In PostgreSQL, auto-increment implies an additional ``generated(_:)``
    /// column constraint. In recognition of this, a future version of this API will handle auto-increment
    /// functionality separately from primary key constraints.
    ///
    /// If the SQL dialect does not specify support for auto-increment, the flag has no effect.
    ///
    /// See also ``SQLTableConstraintAlgorithm/primaryKey(columns:)``.
    case primaryKey(autoIncrement: Bool)

    /// A `NOT NULL` column constraint.
    ///
    /// This is a column-only data constraint; it cannot be specified at the table level.
    case notNull

    /// A `UNIQUE` column constraint, also called a unique key.
    ///
    /// In most SQL dialects, a `UNIQUE` constraint also implies the presence of an index over the constrained column.
    ///
    /// See also ``SQLTableConstraintAlgorithm/unique(columns:)``.
    case unique

    /// A `CHECK` column constraint and its associated validation expression.
    ///
    /// See also ``SQLTableConstraintAlgorithm/check(_:)``.
    case check(any SQLExpression)

    /// A `COLLATE` column constraint, specifying a text collation.
    ///
    /// This is considered an "informative" constraint, describing the behavior of the column's data, rather than a
    /// validation constraint limiting the data itself. In most SQL dialects, it is only valid for columns of textual
    /// data type.
    ///
    /// This is a column-only data constraint; it cannot be specified at the table level.
    case collate(name: any SQLExpression)

    /// A `DEFAULT` column constraint, specifying a default column value.
    ///
    /// This is considered an "informative" constraint, describing the behavior of the column's data, rather than a
    /// validation constraint limiting the data itself.
    ///
    /// This is a column-only data constraint; it cannot be specified at the table level.
    case `default`(any SQLExpression)

    /// A `FOREIGN KEY` column constraint, specifying the referenced data.
    ///
    /// The `references` expression is usually an instance of ``SQLForeignKey``.
    ///
    /// See also ``SQLTableConstraintAlgorithm/foreignKey(columns:references:)``.
    case foreignKey(references: any SQLExpression)

    /// A `GENERATED` column constraint and its associated data-generating expression.
    ///
    /// This can be considered either an "informative" constraint or a validation constraint depending on context.
    ///
    /// Only `STORED` generated columns are currently supported.
    ///
    /// This is a column-only data constraint; it cannot be specified at the table level.
    case generated(any SQLExpression)

    /// An arbitrary expression used in place of a defined constraint.
    ///
    /// This case is redundant with the ability to specify a constraint as an arbitrary ``SQLExpression`` at the next
    /// higher layer of API and should not be used.
    case custom(any SQLExpression)

    /// Equivalent to `.primaryKey(autoIncrement: true)`.
    @inlinable
    public static var primaryKey: SQLColumnConstraintAlgorithm {
        .primaryKey(autoIncrement: true)
    }

    /// Equivalent to `.collate(name: SQLObjectIdentifier(name))`.
    @inlinable
    public static func collate(name: String) -> SQLColumnConstraintAlgorithm {
        .collate(name: SQLObjectIdentifier(name))
    }

    /// Equivalent to `.default(SQLLiteral.string(value))`.
    @inlinable
    public static func `default`(_ value: String) -> SQLColumnConstraintAlgorithm {
        .default(SQLLiteral.string(value))
    }

    /// Equivalent to `.default(SQLLiteral.numeric("\(value)"))`.
    @inlinable
    public static func `default`<T: BinaryInteger>(_ value: T) -> SQLColumnConstraintAlgorithm {
        .default(SQLLiteral.numeric("\(value)"))
    }

    /// Equivalent to `.default(SQLLiteral.numeric("\(value)"))`.
    @inlinable
    public static func `default`<T: FloatingPoint>(_ value: T) -> SQLColumnConstraintAlgorithm {
        .default(SQLLiteral.numeric("\(value)"))
    }

    /// Equivalent to `.default(SQLLiteral.boolean(value))`.
    @inlinable
    public static func `default`(_ value: Bool) -> SQLColumnConstraintAlgorithm {
        .default(SQLLiteral.boolean(value))
    }

    /// Specifies a `FOREIGN KEY` constraint by individual parameters.
    ///
    /// - Parameters:
    ///   - table: The table to reference with the foreign key.
    ///   - column: A column in the referenced table to refer to.
    ///   - onDelete: Desired behavior when the row referenced by the key is deleted (default unspecified).
    ///   - onUpdate: Desired behavior when the row referenced by the key is updated (default unspecified).
    /// - Returns: A configured ``SQLColumnConstraintAlgorithm``.
    @inlinable
    public static func references(
        _ table: String,
        _ column: String,
        onDelete: SQLForeignKeyAction? = nil,
        onUpdate: SQLForeignKeyAction? = nil
    ) -> SQLColumnConstraintAlgorithm {
        self.references(
            SQLObjectIdentifier(table),
            SQLObjectIdentifier(column),
            onDelete: onDelete,
            onUpdate: onUpdate
        )
    }

    /// Specifies a `FOREIGN KEY` constraint by individual parameters.
    ///
    /// - Parameters:
    ///   - table: The table to reference with the foreign key.
    ///   - column: A column in the referenced table to refer to.
    ///   - onDelete: Desired behavior when the row referenced by the key is deleted (default unspecified).
    ///   - onUpdate: Desired behavior when the row referenced by the key is updated (default unspecified).
    /// - Returns: A configured ``SQLColumnConstraintAlgorithm``.
    @inlinable
    public static func references(
        _ table: any SQLExpression,
        _ column: any SQLExpression,
        onDelete: (any SQLExpression)? = nil,
        onUpdate: (any SQLExpression)? = nil
    ) -> SQLColumnConstraintAlgorithm {
        .foreignKey(
            references: SQLForeignKey(
                table: table,
                columns: [column],
                onDelete: onDelete,
                onUpdate: onUpdate
            )
        )
    }
    
    // See `SQLExpression.serialize(to:)`.
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            switch self {
            case .primaryKey(let autoIncrement):
                if autoIncrement, $0.dialect.supportsAutoIncrement {
                    if let function = $0.dialect.autoIncrementFunction {
                        $0.append("DEFAULT", function, "PRIMARY KEY")
                    } else {
                        $0.append("PRIMARY KEY", $0.dialect.autoIncrementClause)
                    }
                } else {
                    $0.append("PRIMARY KEY")
                }
            case .notNull:
                $0.append("NOT NULL")
            case .unique:
                $0.append("UNIQUE")
            case .check(let expression):
                $0.append("CHECK", SQLGroupExpression(expression))
            case .collate(name: let collate):
                $0.append("COLLATE", collate)
            case .default(let expression):
                $0.append("DEFAULT", expression)
            case .foreignKey(let foreignKey):
                $0.append(foreignKey)
            case .generated(let expression):
                $0.append("GENERATED ALWAYS AS", SQLGroupExpression(expression), "STORED")
            case .custom(let expression):
                $0.append(expression)
            }
        }
    }
}