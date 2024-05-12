import FluentKit
import SQLKit

extension DatabaseQuery.Value {
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

extension DatabaseQuery.Field {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(_ identifier: String) -> Self {
        .sql(SQLIdentifier(identifier))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Filter {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(
        _ left: SQLIdentifier,
        _ op: SQLBinaryOperator,
        _ right: any Encodable & Sendable
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
        _ left: any SQLExpression,
        _ op: any SQLExpression,
        _ right: any SQLExpression
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}

extension DatabaseQuery.Join {
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

extension DatabaseQuery.Sort {
    @available(*, deprecated, renamed: "sql(unsafeRaw:)", message: "Renamed to `.sql(unsafeRaw:)`. Please use caution when embedding raw SQL.")
    public static func sql(raw: String) -> Self {
        .sql(unsafeRaw: raw)
    }

    public static func sql(unsafeRaw: String) -> Self {
        .sql(SQLRaw(unsafeRaw))
    }

    public static func sql(
        _ left: SQLIdentifier,
        _ op: SQLBinaryOperator,
        _ right: any Encodable & Sendable
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
        _ left: any SQLExpression,
        _ op: any SQLExpression,
        _ right: any SQLExpression
    ) -> Self {
        .sql(SQLBinaryExpression(left: left, op: op, right: right))
    }

    public static func sql(embed: SQLQueryString) -> Self {
        .sql(embed)
    }

    public static func sql(_ expression: any SQLExpression) -> Self {
        .custom(expression)
    }
}
