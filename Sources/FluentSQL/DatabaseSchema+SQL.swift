extension DatabaseSchema.DataType {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
    }

    public static func sql(_ dataType: SQLDataType) -> Self {
        .sql(dataType as SQLExpression)
    }

    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.Constraint {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
    }

    public static func sql(_ constraint: SQLTableConstraintAlgorithm) -> Self {
        .sql(constraint as SQLExpression)
    }


    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.FieldConstraint {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
    }

    public static func sql(_ constraint: SQLColumnConstraintAlgorithm) -> Self {
        .sql(constraint as SQLExpression)
    }


    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}
