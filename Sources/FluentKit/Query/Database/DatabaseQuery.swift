public struct DatabaseQuery: Sendable {
    public var schema: String
    public var space: String?
    public var customIDKey: FieldKey?
    public var isUnique: Bool
    public var fields: [Field]
    public var action: Action
    public var filters: [Filter]
    public var input: [Value]
    public var joins: [Join]
    public var sorts: [Sort]
    public var limits: [Limit]
    public var offsets: [Offset]

    init(schema: String, space: String? = nil) {
        self.schema = schema
        self.space = space
        self.isUnique = false
        self.fields = []
        self.action = .read
        self.filters = []
        self.input = []
        self.joins = []
        self.sorts = []
        self.limits = []
        self.offsets = []
    }
}

extension DatabaseQuery: CustomStringConvertible {
    public var description: String {
        var parts = [
            "query",
            "\(self.action)",
            "\(self.space.map { "\($0)." } ?? "")\(self.schema)",
        ]
        if self.isUnique {
            parts.append("unique")
        }
        if !self.fields.isEmpty {
            parts.append("fields=\(self.fields)")
        }
        if !self.joins.isEmpty {
            parts.append("joins=\(self.joins)")
        }
        if !self.filters.isEmpty {
            parts.append("filters=\(self.filters)")
        }
        if !self.input.isEmpty {
            parts.append("input=\(self.input)")
        }
        if !self.sorts.isEmpty {
            parts.append("sorts=\(self.sorts)")
        }
        if !self.limits.isEmpty {
            parts.append("limits=\(self.limits)")
        }
        if !self.offsets.isEmpty {
            parts.append("offsets=\(self.offsets)")
        }
        return parts.joined(separator: " ")
    }
    
    var describedByLoggingMetadata: Logger.Metadata {
        var result: Logger.Metadata = [
            "action": "\(self.action)",
            "schema": "\(self.space.map { "\($0)." } ?? "")\(self.schema)",
        ]
        switch self.action {
        case .create, .update, .custom: result["input"] = .array(self.input.map(\.describedByLoggingMetadata))
        default: break
        }
        switch self.action {
        case .read, .aggregate, .custom:
            result["unique"] = "\(self.isUnique)"
            result["fields"] = .array(self.fields.map(\.describedByLoggingMetadata))
            result["joins"] = .array(self.joins.map(\.describedByLoggingMetadata))
            fallthrough
        case .update, .delete:
            result["filters"] = .array(self.filters.map(\.describedByLoggingMetadata))
            result["sorts"] = .array(self.sorts.map(\.describedByLoggingMetadata))
            result["limits"] = .array(self.limits.map { .stringConvertible($0) })
            result["offsets"] = .array(self.offsets.map { .stringConvertible($0) })
        default: break
        }
        return result
    }
}
