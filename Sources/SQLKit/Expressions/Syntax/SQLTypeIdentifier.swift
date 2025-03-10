/// A fundamental syntactical expression - a quoted type identifier (also often referred to as a "type name" or
/// simply "type").
///
/// Type identifiers in most SQL dialects are names of either built-in data types or, if supported by the dialect,
/// custom user-defined types. Type identifiers may or may not follow the same rules as object identifiers; see
/// ``SQLObjectIdentifier`` for additional details.
///
/// In most SQL dialects, quoting is only required for identifiers if they contain characters not otherwise allowed in
/// identifiers in that dialect or conflict with an SQL keyword, but may be used even when not needed. Some dialects,
/// usually those which do not support user-defined types, do not allow quoting type identifiers at all. For the sake of
/// maximum correctness and consistency, and of avoiding expensive checks for invalid characters, ``SQLTypeIdentifier``
/// adds quoting unconditionally unless the dialect does not specify a type identifier quote.
///
/// When a type identifier quote is given, to avoid the risk of accidental SQL injection vulnerabilities, identifiers are
/// scanned for the identifier quote character(s) themselves in addition to quoting; if found, they are escaped appropriately
/// (by doubling any embedded quoting character(s), a syntax supported by all known dialects).
public struct SQLTypeIdentifier: SQLExpression {
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
        if let rawQuote = serializer.dialect.typeIdentifierQuote {
            let escapedString = self.string.replacing(rawQuote, with: "\(rawQuote)\(rawQuote)")

            serializer.write("\(rawQuote)\(escapedString)\(rawQuote)")
        } else {
            serializer.write(self.string)
        }
    }
}
