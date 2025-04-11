/// A straightforward implementation of `CodingKey`, used to represent arbitrary keys.
///
/// > Note: Both the purpose and implementation of this type are almost exactly identical
/// > to those of the standard library's internal [`_DictionaryCodingKey`] type.
///
/// ![Quotation](codingkey-quotation)
///
/// [`_DictionaryCodingKey`]: https://github.com/apple/swift/blob/swift-6.1-RELEASE/stdlib/public/core/Codable.swift#L6123
package enum BasicCodingKey: CodingKey, Hashable {
    /// String representation.
    case key(String)

    /// Integer representation.
    case index(Int)
    
    // See `CodingKey.stringValue`.
    package var stringValue: String {
        switch self {
        case .index(let index): "\(index)"
        case .key(let key):     key
        }
    }
    
    // See `CodingKey.intValue`.
    package var intValue: Int? {
        switch self {
        case .index(let index): index
        case .key(let key):     Int(key)
        }
    }
    
    // See `CodingKey.init(stringValue:)`.
    package init?(stringValue: String) {
        self = .key(stringValue)
    }
    
    // See `CodingKey.init(intValue:)`.
    package init?(intValue: Int) {
        self = .index(intValue)
    }

    /// Create a ``BasicCodingKey`` from the content of any `CodingKey`.
    package init(_ codingKey: some CodingKey) {
        if let intValue = codingKey.intValue {
            self = .index(intValue)
        } else {
            self = .key(codingKey.stringValue)
        }
    }
    
    /// Create a ``BasicCodingKey`` from the coding key of any `CodingKeyRepresentable` value.
    package init(_ codingKeyRepresentable: some CodingKeyRepresentable) {
        self.init(codingKeyRepresentable.codingKey)
    }
}

extension BasicCodingKey: CustomStringConvertible {
    // See `CustomStringConvertible.description`.
    package var description: String {
        switch self {
        case .index(let index): String(describing: index)
        case .key(let key):     String(describing: key)
        }
    }
}

extension BasicCodingKey: CustomDebugStringConvertible {
    // See `CustomDebugStringConvertible.debugDescription`.
    package var debugDescription: String {
        switch self {
        case .index(let index): String(reflecting: index)
        case .key(let key):     String(reflecting: key)
        }
    }
}

extension BasicCodingKey: ExpressibleByStringLiteral {
    // See `ExpressibleByStringLiteral.init(stringLiteral:)`.
    package init(stringLiteral: String) {
        self = .key(stringLiteral)
    }
}

extension BasicCodingKey: ExpressibleByIntegerLiteral {
    // See `ExpressibleByIntegerLiteral.init(integerLiteral:)`.
    package init(integerLiteral: Int) {
        self = .index(integerLiteral)
    }
}
