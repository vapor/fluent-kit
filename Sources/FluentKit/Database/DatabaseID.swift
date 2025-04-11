/// A predefined identifier for a particular database configuration.
///
/// An instance of ``DatabaseID`` acts as a name assigned to a specific configuration.
/// There are no restrictions on the content of the identifier, except that the same
/// identifier may not be assigned to more than one configuration.
///
/// The typical usage of ``DatabaseID`` is to define a static property for each
/// non-default configuration in an extension:
///
/// ```swift
/// extension DatabaseID {
///     static let readOnly = Self("readOnly")
///     static let readWrite = Self("readWrite")
/// }
/// ```
///
/// There is no requirement that ``DatabaseID/default`` be used to identify any configuration;
/// it is provided solely for the sake of convenience in the most common case of having only a
/// single configuration in use.
public struct DatabaseID: Hashable, Codable, Sendable, CustomStringConvertible {
    /// The identifier string.
    ///
    /// The content of the identifier is irrelevant, so long as it is unique among all identifiers
    /// in use. Two ``DatabaseID``s with the same ``DatabaseID/identifier`` are considered equal.
    public let identifier: String

    /// Create a new ``DatabaseID``.
    ///
    /// - Parameter identifier: The identifier string.
    public init(_ identifier: String) {
        self.identifier = identifier
    }

    // See `CustomStringConvertible.description`.
    public var description: String {
        "DatabaseID(\(self.identifier))"
    }

    /// The predefined "default" ``DatabaseID``.
    public static let `default` = Self("__default__")
}
