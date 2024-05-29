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
        ]
        if let space = self.space {
            parts.append("\(space).\(self.schema)")
        } else {
            parts.append(self.schema)
        }
        if self.isUnique {
            parts.append("unique")
        }
        if !self.fields.isEmpty {
            parts.append("fields=\(self.fields)")
        }
        if !self.filters.isEmpty {
            parts.append("filters=\(self.filters)")
        }
        if !self.input.isEmpty {
            parts.append("input=\(self.input)")
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
        func valueMetadata(_ input: DatabaseQuery.Value) -> Logger.MetadataValue {
            switch input {
            case .dictionary(let d): return .dictionary(.init(uniqueKeysWithValues: d.map { ($0.description, valueMetadata($1)) }))
            case .array(let a): return .array(a.map { valueMetadata($0) })
            default: return .stringConvertible(input)
            }
        }

        return [
            "action": "\(self.action)",
            "schema": "\(self.space.map { "\($0)." } ?? "")\(self.schema)",
            "unique": "\(self.isUnique)",
            "fields": .array(self.fields.map { .stringConvertible($0) }),
            "filters": .array(self.filters.map { .stringConvertible($0) }),
            "input": self.input.count == 1 ? valueMetadata(self.input.first!) : .array(self.input.map { valueMetadata($0) }),
            "limits": .array(self.limits.map { .stringConvertible($0) }),
            "offsets": .array(self.offsets.map { .stringConvertible($0) }),
        ]
    }
}
