import Tracing

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

    var serviceContext: ServiceContext
    let shouldTrace: Bool

    init(schema: String, space: String? = nil, shouldTrace: Bool = false) {
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
        self.serviceContext = ServiceContext.current ?? .topLevel
        self.shouldTrace = shouldTrace
    }

    func withTracing<T>(_ closure: () async throws -> T) async rethrows -> T {
        if shouldTrace {
            try await withSpan("db.query", context: self.serviceContext, ofKind: .server) { span in
                // https://opentelemetry.io/docs/specs/semconv/database/database-spans/#span-definition
                // We add what we can. The rest is up to the underlying driver packages
                span.updateAttributes { attributes in
                    // db.system.name
                    attributes["db.collection.name"] = self.schema
                    attributes["db.namespace"] = self.space
                    attributes["db.operation.name"] = "\(self.action)"
                    // db.response.status_code
                    // error.type
                    // server.port
                    attributes["db.query.summary"] = "\(self.action) \(self.space.map { "\($0)." } ?? "")\(self.schema)"
                }
                return try await closure()
            }
        } else {
            try await closure()
        }
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
        case .create, .update, .custom:
            result["input"] = .array(self.input.map(\.describedByLoggingMetadata))
        default: break
        }
        switch self.action {
        case .read, .aggregate, .custom:
            result["unique"] = .stringConvertible(self.isUnique)
            result["fields"] = .array(self.fields.map(\.describedByLoggingMetadata))
            result["joins"] = .array(self.joins.map(\.describedByLoggingMetadata))
            fallthrough
        case .update, .delete:
            result["filters"] = .array(self.filters.map(\.describedByLoggingMetadata))
            result["sorts"] = .array(self.sorts.map(\.describedByLoggingMetadata))
            result["limits"] = .array(self.limits.map(\.describedByLoggingMetadata))
            result["offsets"] = .array(self.offsets.map(\.describedByLoggingMetadata))
        default: break
        }
        return result
    }
}
