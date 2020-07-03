import FluentKit
import SQLKit

public extension SQLQueryString.StringInterpolation {
    mutating func appendInterpolation(_ fieldKey: FieldKey) {
        appendLiteral(fieldKey.description)
    }
}
