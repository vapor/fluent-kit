import SQLKit

/// This file provides a few extensions to SQLKit's ``SQLList`` which have the effect of mimicking
/// the public API which was previously provided by a nearly-identical type of the same name in
/// this module. The slightly differing behavior of the Fluent version had a tendency to cause
/// confusion when both `FluentSQL` and `SQLKit` were imported in the same context; as such, the
/// Fluent version was removed. To avoid breaking API that has been publicly available for a long
/// time (no matter how incorrectly so), these deprecated extensions make the semantics of the removed
/// Fluent implementation available. Whether the original or alternate serialization behavior is used
/// is based on which initializer is used. The original SQLKit initializer, ``init(_:separator:)`` (or
/// ``init(_:)``, taking the default value for the separator), gives the original and intended behavior
/// (see ``SQLKit/SQLList`` for further details). The convenience intializer, ``init(items:separator:)``,
/// enables the deprecated alternate behavior, which adds a space character before and after the separator.
///
/// Examples:
///
///     Expressions: [1, 2, 3, 4, 5]
///     Separator: "AND"
///     Original serialization: 1AND2AND3AND4AND5
///     Alternate serialization: 1 AND 2 AND 3 AND 4 AND 5
///
///     Expressions: [1, 2, 3, 4, 5]
///     Separator: ", "
///     Original serialization: 1, 2, 3, 4, 5
///     Alternate serialization: 1 ,  2 ,  3 ,  4 ,  5
///
/// - Warning: These extensions are not recommended, as it was never intended for this behavior to be
///   public. Convert code using these extensions to invoke the original ``SQLKit/SQLList`` directly.
extension SQLKit.SQLList {
    @available(*, deprecated, message: "Use `expressions` instead.")
    public var items: [SQLExpression] {
        get { self.expressions }
        set { self.expressions = newValue }
    }
    
    @available(*, deprecated, message: "Use `init(_:separator:)` and include whitespace in the separator as needed instead.")
    public init(items: [SQLExpression], separator: SQLExpression) {
        self.init(items, separator: " \(separator) " as SQLQueryString)
    }
}

@available(*, deprecated, message: "Import `SQLList` from the SQLKit module instead.")
public typealias SQLList = SQLKit.SQLList
