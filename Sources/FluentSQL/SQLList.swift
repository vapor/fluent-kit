import FluentKit
import SQLKit

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
