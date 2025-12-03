import FluentKit
import SQLKit

/// A thin deprecated wrapper around `SQLNestedSubpathExpression`.
@available(*, deprecated, message: "Replaced by `SQLNestedSubpathExpression` in SQLKit")
public struct SQLJSONColumnPath: SQLExpression {
    private var realExpression: SQLNestedSubpathExpression

    public var column: String {
        get { (self.realExpression.column as? SQLIdentifier)?.string ?? "" }
        set { self.realExpression.column = SQLIdentifier(newValue) }
    }

    public var path: [String] {
        get { self.realExpression.path }
        set { self.realExpression.path = newValue }
    }

    public init(column: String, path: [String]) {
        self.realExpression = .init(column: column, path: path)
    }

    public func serialize(to serializer: inout SQLSerializer) {
        self.realExpression.serialize(to: &serializer)
    }
}

extension DatabaseQuery.Field {
    public static func sql(json column: String, _ path: String...) -> Self {
        .sql(json: column, path)
    }

    public static func sql(json column: String, _ path: [String]) -> Self {
        .sql(SQLNestedSubpathExpression(column: column, path: path))
    }
}
