/// Represents a value's type in SQL.
///  
/// In practice it is not generally possible to list all of the data types supported by any given database, nor
/// to define a useful set of types with identical behaviors which are available across all databases, despite the
/// attempted influence of ANSI SQL. As such, this type primarily functions as a front end for
/// ``SQLDialect/customDataType(for:)-2firt``.
public enum SQLDataType: SQLExpression {
    /// Translates to `SMALLINT`, unless overriden by dialect. Usually an integer with at least 16-bit range.
    case smallint
    
    /// Translates to `INTEGER`, unless overridden by dialect. Usually an integer with at least 32-bit range.
    case int
    
    /// Translates to `BIGINT`, unless overridden by dialect. Almost always an integer with 64-bit range.
    case bigint
    
    /// Translates to `REAL`, unless overridden by dialect. Usually a decimal value with at least 32-bit precision.
    case real

    /// Translates to `TEXT`, unless overridden by dialect. Represents non-binary textual data (i.e. human-readable
    /// text potentially having an explicit character set and collation).
    case text
    
    /// Translates to `BLOB`, unless overridden by dialect. Represents binary non-textual data (i.e. an arbitrary
    /// byte string admitting of no particular format or representation).
    case blob

    /// Translates to `TIMESTAMP`, unless overridden by dialect. Represents a type suitable for storing the encoded
    /// value of a `Date` in a form which can be saved to and reloaded from the database without suffering skew caused
    /// by time zone calculations.
    case timestamp

    /// Translates to the type specification for an enumeration, depending on the support expressed by the dialect,
    /// unless separately overridden by the dialect. See ``SQLEnumSyntax`` for details of possible support. For inline
    /// support, the resulting type is `ENUM(case1[, case2[, ...]])`. For typename support, the resulting type is the
    /// given name. If enums are unsupported, the resulting type is ``SQLDataType/text``.
    case enumeration(name: String, cases: [String])

    /// Translates to the given string, unless overridden by dialect.
    case custom(String)

    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        if let dialect = serializer.dialect.customDataType(for: self) {
            serializer.write(dialect)
        } else {
            switch self {
            case .smallint:
                SQLTypeIdentifier("SMALLINT").serialize(to: &serializer)
            case .int:
                SQLTypeIdentifier("INTEGER").serialize(to: &serializer)
            case .bigint:
                SQLTypeIdentifier("BIGINT").serialize(to: &serializer)
            case .text:
                SQLTypeIdentifier("TEXT").serialize(to: &serializer)
            case .real:
                SQLTypeIdentifier("REAL").serialize(to: &serializer)
            case .blob:
                SQLTypeIdentifier("BLOB").serialize(to: &serializer)
            case .timestamp:
                SQLTypeIdentifier("TIMESTAMP").serialize(to: &serializer)
            case .enumeration(let name, let cases):
                switch serializer.dialect.enumSyntax {
                case .typeName: SQLTypeIdentifier(name).serialize(to: &serializer)
                case .inline: SQLTypeIdentifier("ENUM(\(cases.joined(separator: ",")))").serialize(to: &serializer)
                case .unsupported: SQLDataType.text.serialize(to: &serializer)
                }
            case .custom(let str):
                SQLTypeIdentifier(str).serialize(to: &serializer)
            }
        }
    }
}
