/// Common definitions for any query builder which permits specifying a secondary predicate.
///
/// - Expressions specified with ``having(_:)`` are considered conjunctive (`AND`).
/// - Expressions specified with ``orHaving(_:)`` are considered inclusively disjunctive (`OR`).
///
/// See ``SQLSecondaryPredicateGroupBuilder`` for details of grouping expressions (e.g. with parenthesis).
public protocol SQLSecondaryPredicateBuilder: AnyObject {
    /// The secondary predicate under construction.
    var secondaryPredicate: (any SQLExpression)? { get set }
}

// MARK: - Conjunctive (AND)

extension SQLSecondaryPredicateBuilder {
    // MARK: - Column/value comparison
    
    /// Adds a column to encodable comparison to this builder's `HAVING` clause by `AND`ing.
    ///
    ///     builder.having("name", .equal, "Earth")
    ///
    /// The encodable value supplied will be bound to the query as a parameter.
    ///
    ///     SELECT * FROM "planets" HAVING "name" = $0 ["Earth"]
    @inlinable
    @discardableResult
    public func having(_ lhs: String, _ op: SQLBinaryOperator, _ rhs: some Encodable & Sendable) -> Self {
        self.having(SQLColumn(lhs), op, SQLBind(rhs))
    }

    /// Adds a column to encodable array comparison to this builder's `HAVING` clause by `AND`ing.
    ///
    ///     builder.having("name", .equal, ["Earth", "Mars"])
    ///
    /// The encodable values supplied will be bound to the query as parameters.
    ///
    ///     SELECT * FROM "planets" HAVING "name" IN ($0, $1) ["Earth", "Mars"]
    @inlinable
    @discardableResult
    public func having(_ lhs: String, _ op: SQLBinaryOperator, _ rhs: [some Encodable & Sendable]) -> Self {
        self.having(SQLColumn(lhs), op, SQLBind.group(rhs))
    }

    /// Adds a column to encodable comparison to this builder's `HAVING` clause by `AND`ing.
    ///
    ///     builder.having("name", .equal, "Earth")
    ///
    /// The encodable value supplied will be bound to the query as a parameter.
    ///
    ///     SELECT * FROM "planets" HAVING "name" = $0 ["Earth"]
    @inlinable
    @discardableResult
    public func having(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, _ rhs: some Encodable & Sendable) -> Self {
        self.having(SQLColumn(lhs), op, SQLBind(rhs))
    }

    /// Adds a column to encodable array comparison to this builder's `HAVING` clause by `AND`ing.
    ///
    ///     builder.having("name", .in, ["Earth", "Mars"])
    ///
    /// The encodable values supplied will be bound to the query as parameters.
    ///
    ///     SELECT * FROM "planets" HAVING "name" IN ($0, $1) ["Earth", "Mars"]
    @inlinable
    @discardableResult
    public func having(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, _ rhs: [some Encodable & Sendable]) -> Self {
        self.having(SQLColumn(lhs), op, SQLBind.group(rhs))
    }

    // MARK: - Column/column comparison

    /// Adds a column to column comparison to this builder's `HAVING` clause by `AND`ing.
    ///
    ///     builder.having("firstName", .equal, column: "lastName")
    ///
    /// This method compares two _columns_.
    ///
    ///     SELECT * FROM "users" HAVING "firstName" = "lastName"
    @inlinable
    @discardableResult
    public func having(_ lhs: String, _ op: SQLBinaryOperator, column rhs: String) -> Self {
        self.having(SQLColumn(lhs), op, SQLColumn(rhs))
    }

    /// Adds a column to column comparison to this builder's `HAVING` clause by `AND`ing.
    ///
    ///     builder.having("firstName", .equal, column: "lastName")
    ///
    /// This method compares two _columns_.
    ///
    ///     SELECT * FROM "users" HAVING "firstName" = "lastName"
    @inlinable
    @discardableResult
    public func having(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, column rhs: SQLObjectIdentifier) -> Self {
        self.having(SQLColumn(lhs), op, SQLColumn(rhs))
    }

    // MARK: - Column/expression comparison

    /// Adds a column to expression comparison to this builder' `HAVING` clause by `AND`ing.
    @inlinable
    @discardableResult
    public func having(_ lhs: String, _ op: SQLBinaryOperator, _ rhs: any SQLExpression) -> Self {
        self.having(SQLColumn(lhs), op, rhs)
    }

    /// Adds a column to expression comparison to this builder's `HAVING` clause by `AND`ing.
    @inlinable
    @discardableResult
    public func having(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, _ rhs: any SQLExpression) -> Self {
        self.having(SQLColumn(lhs), op, rhs)
    }

    // MARK: - Expressions

    /// Adds an expression to expression comparison to this builder's `HAVING` clause by `AND`ing.
    @inlinable
    @discardableResult
    public func having(_ lhs: any SQLExpression, _ op: SQLBinaryOperator, _ rhs: any SQLExpression) -> Self {
        self.having(lhs, op as any SQLExpression, rhs)
    }

    /// Adds an expression to expression comparison with arbitrary operator expression to this
    /// builder's `HAVING` clause by `AND`ing.
    @inlinable
    @discardableResult
    public func having(_ lhs: any SQLExpression, _ op: any SQLExpression, _ rhs: any SQLExpression) -> Self {
        self.having(SQLBinaryExpression(left: lhs, op: op, right: rhs))
    }

    /// Adds an expression to this builder's `HAVING` clause by `AND`ing.
    @inlinable
    @discardableResult
    public func having(_ expression: any SQLExpression) -> Self {
        if let existing = self.secondaryPredicate {
            self.secondaryPredicate = SQLBinaryExpression(left: existing, op: SQLBinaryOperator.and, right: expression)
        } else {
            self.secondaryPredicate = expression
        }
        return self
    }
}

// MARK: - Inclusively disjunctive (OR)

extension SQLSecondaryPredicateBuilder {
    // MARK: - Column/value comparison
    
    /// Adds a column to encodable comparison to this builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: String, _ op: SQLBinaryOperator, _ rhs: some Encodable & Sendable) -> Self {
        self.orHaving(SQLColumn(lhs), op, SQLBind(rhs))
    }

    /// Adds a column to encodable array comparison to this builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: String, _ op: SQLBinaryOperator, _ rhs: [some Encodable & Sendable]) -> Self {
        self.orHaving(SQLColumn(lhs), op, SQLBind.group(rhs))
    }

    /// Adds a column to encodable comparison to this builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, _ rhs: some Encodable & Sendable) -> Self {
        self.orHaving(SQLColumn(lhs), op, SQLBind(rhs))
    }

    /// Adds a column to encodable array comparison to this builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, _ rhs: [some Encodable & Sendable]) -> Self {
        self.orHaving(SQLColumn(lhs), op, SQLBind.group(rhs))
    }

    // MARK: - Column/column comparison

    /// Adds a column to column comparison to this builder's `HAVING` clause by `OR`ing.
    ///
    ///     builder.having(SQLLiteral.boolean(false)).orHaving("firstName", .equal, column: "lastName")
    ///
    /// This method compares two _columns_.
    ///
    ///     SELECT * FROM "users" HAVING 0 OR "firstName" = "lastName"
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: String, _ op: SQLBinaryOperator, column rhs: String) -> Self {
        self.orHaving(SQLColumn(lhs), op, SQLColumn(rhs))
    }

    /// Adds a column to column comparison to this builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, column rhs: SQLObjectIdentifier) -> Self {
        self.orHaving(SQLColumn(lhs), op, SQLColumn(rhs))
    }
    
    // MARK: - Column/expression comparison

    /// Adds a column to expression comparison to the `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: String, _ op: SQLBinaryOperator, _ rhs: any SQLExpression) -> Self {
        self.orHaving(SQLColumn(lhs), op, rhs)
    }
    
    /// Adds a column to expression comparison to the `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: SQLObjectIdentifier, _ op: SQLBinaryOperator, _ rhs: any SQLExpression) -> Self {
        self.orHaving(SQLColumn(lhs), op, rhs)
    }

    // MARK: - Expressions

    /// Adds an expression to expression comparison to this builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: any SQLExpression, _ op: SQLBinaryOperator, _ rhs: any SQLExpression) -> Self {
        self.orHaving(lhs, op as any SQLExpression, rhs)
    }

    /// Adds an expression to expression comparison with arbitrary operator expression to this
    /// builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ lhs: any SQLExpression, _ op: any SQLExpression, _ rhs: any SQLExpression) -> Self {
        self.orHaving(SQLBinaryExpression(left: lhs, op: op, right: rhs))
    }

    /// Adds an expression to this builder's `HAVING` clause by `OR`ing.
    @inlinable
    @discardableResult
    public func orHaving(_ expression: any SQLExpression) -> Self {
        if let existing = self.secondaryPredicate {
            self.secondaryPredicate = SQLBinaryExpression(left: existing, op: SQLBinaryOperator.or, right: expression)
        } else {
            self.secondaryPredicate = expression
        }
        return self
    }
}
