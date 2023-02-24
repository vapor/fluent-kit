import SQLKit
import FluentKit

public struct SQLJSONColumnPath: SQLExpression {
    public var column: String
    public var path: [String]

    public init(column: String, path: [String]) {
        self.column = column
        self.path = path
    }

    public func serialize(to serializer: inout SQLSerializer) {
        switch serializer.dialect.name {
        case "postgresql":
            switch path.count {
            case 1:
                serializer.write("\(column)->>'\(path[0])'")
            case 2...:
                let inner = path[0..<path.count - 1].map { "'\($0)'" }.joined(separator: "->")
                serializer.write("\(column)->\(inner)->>'\(path.last!)'")
            default:
                fatalError("Impossible path array count serializing column \(self.column) as JSON")
            }
        default:
            let path = self.path.joined(separator: ".")
            serializer.write("JSON_EXTRACT(\(column), '$.\(path)')")
        }
    }
}

extension DatabaseQuery.Field {
    public static func sql(json column: String, _ path: String...) -> Self {
        .sql(json: column, path)
    }

    public static func sql(json column: String, _ path: [String]) -> Self {
        .sql(SQLJSONColumnPath(column: column, path: path))
    }
}
