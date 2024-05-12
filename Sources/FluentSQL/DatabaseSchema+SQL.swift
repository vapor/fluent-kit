import FluentKit
import SQLKit

extension DatabaseSchema.DataType {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(_ dataType: SQLDataType) -> Self {
        .sql(dataType as any SQLExpression)
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.Constraint {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(_ constraint: SQLTableConstraintAlgorithm) -> Self {
        .sql(constraint as any SQLExpression)
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.ConstraintAlgorithm {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
    .custom(expression)
    }
}

extension DatabaseSchema.FieldConstraint {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(_ constraint: SQLColumnConstraintAlgorithm) -> Self {
        .sql(constraint as any SQLExpression)
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.FieldDefinition {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.FieldUpdate {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.FieldName {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseSchema.ConstraintDelete {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}
