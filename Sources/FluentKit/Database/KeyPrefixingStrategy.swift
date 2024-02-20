/// A strategy describing how to apply a prefix to a ``FieldKey``.
public enum KeyPrefixingStrategy: CustomStringConvertible {
    /// The "do nothing" strategy - the prefix is applied to each key by simple concatenation.
    case none
    
    /// Each key has its first character capitalized and the prefix is applied to the result.
    case camelCase
    
    /// An underscore is placed between the prefix and each key.
    case snakeCase
    
    /// A custom strategy - for each key, the closure is called with that key and the prefix with which the
    /// wrapper was initialized, and must return the field key to actually use. The closure must be "pure"
    /// (i.e. for any given pair of inputs it must always return the same result, in the same way that hash
    /// values must be consistent within a single execution context).
    case custom((_ prefix: FieldKey, _ idFieldKey: FieldKey) -> FieldKey)
    
    // See `CustomStringConvertible.description`.
    public var description: String {
        switch self {
        case .none:
            return ".useDefaultKeys"
        case .camelCase:
            return ".camelCase"
        case .snakeCase:
            return ".snakeCase"
        case .custom(_):
            return ".custom(...)"
        }
    }
    
    /// Apply this prefixing strategy and the given prefix to the given key, and return the result.
    public func apply(prefix: FieldKey, to key: FieldKey) -> FieldKey {
        switch self {
        case .none:
            return .prefix(prefix, key)
        
        // This strategy converts `.id` and `.aggregate` keys (but not prefixes) into generic `.string()`s.
        case .camelCase:
            switch key {
            case .id, .aggregate, .string(_):
                return .prefix(prefix, .string(key.description.withUppercasedFirstCharacter()))

            case .prefix(let originalPrefix, let originalSuffix):
                return .prefix(self.apply(prefix: prefix, to: originalPrefix), originalSuffix)
            }

        case .snakeCase:
            return .prefix(.prefix(prefix, .string("_")), key)

        case .custom(let closure):
            return closure(prefix, key)
        }
    }
}

fileprivate extension String {
    func withUppercasedFirstCharacter() -> String {
        guard !self.isEmpty else { return self }
        
        var result = self
        result.replaceSubrange(result.startIndex ... result.startIndex, with: result[result.startIndex].uppercased())
        return result
    }
}
