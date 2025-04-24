/// A fundamental syntactical expression - one of several various kinds of literal SQL expressions.
public enum SQLLiteral: SQLExpression {
    /// The `*` symbol, when used as a column name (but _not_ when used as the multiplication operator),
    /// meaning "all columns".
    case all

    /// A literal expression representing the `DEFAULT` keyword in the context of a value in an `INSERT`
    /// value list for the current dialect.
    ///
    /// Expressions should prefer to explicitly spell out the keyword when it is used in other contexts.
    ///
    /// > Warning: This case does **not** currently respect the ``SQLDialect/supportsExplicitDefaultValues-86p94``
    /// > dialect flag, as its alternative expression if the flag is set to `false` would be nothing at all.
    case `default`

    /// A literal expression representing a `NULL` SQL value  in the current dialect.
    ///
    /// > Note: Although `NULL` is a keyword, it nonetheless represents a specific literal value.
    case null

    /// A literal expression representing a boolean literal in the current dialect.
    case boolean(Bool)

    /// A literal expression representing a numeric literal in the current dialect.
    ///
    /// Because the range of supported numeric types between SQL dialects is extremely wide, and that range rarely
    /// at best overlaps cleanly with Swift's numeric type support, numeric literals are specified using their
    /// stringified representations.
    case numeric(String)

    /// A literal expression representing a literal string in the current dialect.
    ///
    /// Literal strings undergo quoting and escaping in exactly the same fashion described by ``SQLObjectIdentifier``,
    /// except the dialect's ``SQLDialect/literalStringQuote-2vqlo`` is used.
    case string(String)

    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        switch self {
        case .all:
            serializer.write("*")

        case .default:
            serializer.write("DEFAULT")

        case .null:
            serializer.write("NULL")

        case .boolean(let bool):
            serializer.write("\(bool)")

        case .numeric(let numeric):
            serializer.write(numeric)

        case .string(let string):
            let rawQuote = serializer.dialect.literalStringQuote

            serializer.write("\(rawQuote)\(string.replacing(rawQuote, with: "\(rawQuote)\(rawQuote)"))\(rawQuote)")
        }
    }
}
