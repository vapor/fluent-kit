extension DatabaseQuery {
    public enum Limit: Sendable {
        case count(Int)

        /// Due to design limitations in SQLKit, it is not possible to provide a custom limit expression;
        /// as such, it is in turn a design flaw of FluentKit that this enum exists at all. Any attempt to
        /// use ``custom(_:)`` in a query unconditionally triggers a fatal error at runtime.
        @available(*, deprecated, message: "`DatabaseQuery.Limit.custom(_:)` does not work.")
        case custom(any Sendable)
    }

    public enum Offset: Sendable {
        case count(Int)

        /// Due to design limitations in SQLKit, it is not possible to provide a custom offset expression;
        /// as such, it is in turn a design flaw of FluentKit that this enum exists at all. Any attempt to
        /// use ``custom(_:)`` in a query unconditionally triggers a fatal error at runtime.
        @available(*, deprecated, message: "`DatabaseQuery.Offset.custom(_:)` triggers a fatal error when used.")
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Limit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .count(let count):
            "count(\(count))"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}

extension DatabaseQuery.Limit {
    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .count(let count): .stringConvertible(count)
        default: "custom"
        }
    }
}

extension DatabaseQuery.Offset: CustomStringConvertible {
    public var description: String {
        switch self {
        case .count(let count):
            "count(\(count))"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}

extension DatabaseQuery.Offset {
    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .count(let count): .stringConvertible(count)
        default: "custom"
        }
    }
}
