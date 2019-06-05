@_exported import FluentKit
@_exported import SQLKit

extension DatabaseQuery.Filter {
    public static func sql(_ expression: SQLExpression) -> DatabaseQuery.Filter {
        return .custom(expression)
    }
}

extension DatabaseQuery.Field {
    public static func sql(_ expression: SQLExpression) -> DatabaseQuery.Field {
        return .custom(expression)
    }
}

public struct SQLList: SQLExpression {
    public var items: [SQLExpression]
    public var separator: SQLExpression

    public init(items: [SQLExpression], separator: SQLExpression) {
        self.items = items
        self.separator = separator
    }

    public func serialize(to serializer: inout SQLSerializer) {
        var first = true
        for el in self.items {
            if !first {
                serializer.write(" ")
                self.separator.serialize(to: &serializer)
                serializer.write(" ")
            }
            first = false
            el.serialize(to: &serializer)
        }
    }
}

/// Wraps a non-generic `Encodable` type for passing to a method that requires
/// a strong type.
///
///     let encodable: Encodable ...
///     let data = try JSONEncoder().encode(EncodableWrapper(encodable))
///
struct EncodableWrapper: Encodable {
    /// Wrapped `Encodable` type.
    public let encodable: Encodable
    
    /// Creates a new `EncoderWrapper`.
    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    /// `Encodable` conformance.
    public func encode(to encoder: Encoder) throws {
        try self.encodable.encode(to: encoder)
    }
}
