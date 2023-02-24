import FluentKit
import SQLKit

extension DatabaseQuery.Value {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
    }
    
    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Field {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
    }

    public static func sql(_ identifier: String) -> Self {
        .sql(SQLIdentifier(identifier))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Filter {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
    }

    public static func sql(
        _ left: SQLIdentifier,
        _ op: SQLBinaryOperator,
        _ right: Encodable
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: SQLBind(right)))
    }

    public static func sql(
        _ left: SQLIdentifier,
        _ op: SQLBinaryOperator,
        _ right: SQLIdentifier
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(
        _ left: SQLExpression,
        _ op: SQLExpression,
        _ right: SQLExpression
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Sort {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
    }

    public static func sql(
        _ left: SQLIdentifier,
        _ op: SQLBinaryOperator,
        _ right: Encodable
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: SQLBind(right)))
    }

    public static func sql(
        _ left: SQLIdentifier,
        _ op: SQLBinaryOperator,
        _ right: SQLIdentifier
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(
        _ left: SQLExpression,
        _ op: SQLExpression,
        _ right: SQLExpression
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}
