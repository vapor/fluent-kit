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
    /// See `SQLExpression`.
    public func serialize(to serializer: inout SQLSerializer) {
        SQLIdentifier(self.string(for: serializer.dialect))
            .serialize(to: &serializer)
    }

    // Converts `FieldKey` to a string.
    // 
    // `.description` is not used here since that isn't
    // _necessarily_ a SQL compatible value.
    //
    // SQLSerializer is passed in case a different dialect may
    // need to have special values for id / aggregate.
    private func string(for dialect: SQLDialect) -> String {
        switch self {
        case .id:
            return "id"
        case .aggregate:
            return "aggregate"
        case .prefix(let prefix, let key):
            return prefix.string(for: dialect) + key.string(for: dialect)
        case .string(let string):
            return string
        }
    }
}
