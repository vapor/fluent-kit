extension DatabaseQuery.Value {
    public static func sql(raw: String) -> Self {
        .sql(SQLRaw(raw))
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

    public static func sql(_ expression: SQLExpression) -> Self {
        .custom(expression)
    }
}

extension FieldKey: SQLExpression {
    public func serialize(to serializer: inout SQLSerializer) {
        switch self {
        case .id:
            serializer.write("id")
        case .aggregate:
            serializer.write("aggregate")
        case .prefix(let prefix, let key):
            prefix.serialize(to: &serializer)
            key.serialize(to: &serializer)
        case .string(let string):
            serializer.write(string)
        }
    }
}
