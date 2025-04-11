import FluentKit
import SQLKit

extension DatabaseQuery.Action {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Aggregate {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Aggregate.Method {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Field {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(_ identifier: String) -> Self {
        .sql(SQLObjectIdentifier(identifier))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }

    public static func sql(json column: String, _ path: String...) -> Self {
        .sql(json: column, path)
    }

    public static func sql(json column: String, _ path: [String]) -> Self {
        .sql(SQLNestedSubpathExpression(column: column, path: path))
    }
}

extension DatabaseQuery.Filter {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(
        _ left: SQLObjectIdentifier,
        _ op: SQLBinaryOperator,
        _ right: any Encodable & Sendable
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: SQLBind(right)))
    }

    public static func sql(
        _ left: SQLObjectIdentifier,
        _ op: SQLBinaryOperator,
        _ right: SQLObjectIdentifier
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(
        _ left: some SQLExpression,
        _ op: some SQLExpression,
        _ right: some SQLExpression
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Filter.Method {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Filter.Relation {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Join {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Join.Method {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

// `DatabaseQuery.Limit` and `DatabaseQuery.Offset` do not have `.sql()` extension methods because use
// of the `.custom()` cases of these types triggers a `fatalError()` in `SQLQueryConverter`.

extension DatabaseQuery.Sort {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(
        _ left: SQLObjectIdentifier,
        _ op: SQLBinaryOperator,
        _ right: any Encodable & Sendable
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: SQLBind(right)))
    }

    public static func sql(
        _ left: SQLObjectIdentifier,
        _ op: SQLBinaryOperator,
        _ right: SQLObjectIdentifier
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(
        _ left: some SQLExpression,
        _ op: some SQLExpression,
        _ right: some SQLExpression
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Sort.Direction {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Value {
    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLUnsafeRaw(unsafeRaw))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: some SQLExpression) -> Self {
        .custom(expression)
    }
}
