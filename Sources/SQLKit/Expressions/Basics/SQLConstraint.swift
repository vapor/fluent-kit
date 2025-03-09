/// An expression representing the combination of a constraint name and algorithm for table constraints.
///
/// See ``SQLTableConstraintAlgorithm``.
public struct SQLConstraint<NameExpr: SQLExpression, AlgExpr: SQLExpression>: SQLExpression {
    /// The constraint's name, if any.
    ///
    /// It is pointless to use ``SQLConstraint`` in the absence of a ``name``, but the optionality is part of
    /// preexisting public API and cannot be changed.
    public var name: NameExpr?

    /// The constraint's algorithm.
    ///
    /// See ``SQLTableConstraintAlgorithm``.
    public var algorithm: AlgExpr

    /// Create an ``SQLConstraint``.
    ///
    /// - Parameters:
    ///   - algorithm: The constraint algorithm.
    ///   - name: The optional constraint name.
    @inlinable
    public init(algorithm: AlgExpr, name: NameExpr? = nil) {
        self.name = name
        self.algorithm = algorithm
    }

    // See `SQLExpression.serialize(to:)`.
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            if let name = self.name {
                let normalized = $0.dialect.normalizeSQLConstraint(identifier: name)
                $0.append("CONSTRAINT", normalized)
            }
            $0.append(self.algorithm)
        }
    }
}
