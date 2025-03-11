/// A fundamental syntactical expression - a quoted object identifier (also often referred to as a "name" or
/// "object name").
///
/// Most identifiers in many SQL dialects are references to various objects - tables, columns, functions, indexes,
/// constraints, etc.; if something is not a keyword, punctuation, or a literal, it is more likely than not an object
/// identifier. Names of data types may or may not follow the same rules as object identifiers; see ``SQLTypeIdentifier``
/// for additional details.
///
/// In most SQL dialects, quoting is only required for identifiers if they contain characters not otherwise allowed in
/// identifiers in that dialect or conflict with an SQL keyword, but may be used even when not needed. For the sake of
/// maximum correctness and consistency, and of avoiding expensive checks for invalid characters, ``SQLObjectIdentifier``
/// adds quoting unconditionally.
///
/// To avoid the risk of accidental SQL injection vulnerabilities, in addition to quoting, identifiers are scanned for
/// the identifier quote character(s) themselves; if found, they are escaped appropriately (by doubling any embedded
/// quoting character(s), a syntax supported by all known dialects).
public struct SQLObjectIdentifier: SQLExpression {
    /// The actual identifier, unescaped and unquoted.
    public let string: String

    /// Create an identifier with a string.
    @inlinable
    public init(_ string: some StringProtocol) {
        self.string = String(string)
    }

    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        let rawQuote = serializer.dialect.objectIdentifierQuote
        let escapedString = self.string.replacing(rawQuote, with: "\(rawQuote)\(rawQuote)")

        serializer.write("\(rawQuote)\(escapedString)\(rawQuote)")
    }
}
