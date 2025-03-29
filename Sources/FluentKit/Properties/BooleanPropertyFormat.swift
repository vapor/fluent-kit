/// A conversion between `Bool` and an arbitrary alternative storage format, usually a string.
public protocol BooleanPropertyFormat: Sendable {
    associatedtype Value: Codable & Sendable

    init()

    func parse(_ value: Value) -> Bool?
    func serialize(_ bool: Bool) -> Value
}

/// Represent a `Bool` natively, using the database's underlying support (if any). This is the default.
public struct DefaultBooleanPropertyFormat: BooleanPropertyFormat {
    public init() {}
    
    public func parse(_ value: Bool) -> Bool? {
        value
    }
    
    public func serialize(_ bool: Bool) -> Bool {
        bool
    }
}

extension BooleanPropertyFormat where Self == DefaultBooleanPropertyFormat {
    public static var `default`: Self { .init() }
}

/// Represent a `Bool` as any integer type. Any value other than `0` or `1` is considered invalid.
///
/// > Note: This format is primarily useful when the underlying database's native boolean format is
/// > an integer of different width than the one that was used by the model - for example, a MySQL
/// > model with a `BIGINT` field instead of the default `TINYINT`.
public struct IntegerBooleanPropertyFormat<T: FixedWidthInteger & Codable & Sendable>: BooleanPropertyFormat {
    public init() {}
    
    public func parse(_ value: T) -> Bool? {
        switch value {
        case .zero: false
        case .zero.advanced(by: 1): true
        default: nil
        }
    }
    
    public func serialize(_ bool: Bool) -> T {
        .zero.advanced(by: bool ? 1 : 0)
    }
}

extension BooleanPropertyFormat where Self == IntegerBooleanPropertyFormat<Int> {
    public static var integer: Self { .init() }
}

/// Represent a `Bool` as the strings "0" and "1". Any other value is considered invalid.
public struct OneZeroBooleanPropertyFormat: BooleanPropertyFormat {
    public init() {}
    
    public func parse(_ value: String) -> Bool? {
        switch value {
        case "0": false
        case "1": true
        default: nil
        }
    }
    
    public func serialize(_ bool: Bool) -> String {
        bool ? "1" : "0"
    }
}

extension BooleanPropertyFormat where Self == OneZeroBooleanPropertyFormat {
    public static var oneZero: Self { .init() }
}

/// Represent a `Bool` as the strings "N" and "Y". Parsing is case-insensitive. Serialization always stores uppercase.
public struct YNBooleanPropertyFormat: BooleanPropertyFormat {
    public init() {}
    
    public func parse(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "n": false
        case "y": true
        default: nil
        }
    }
    
    public func serialize(_ bool: Bool) -> String {
        bool ? "Y" : "N"
    }
}

extension BooleanPropertyFormat where Self == YNBooleanPropertyFormat {
    public static var yn: Self { .init() }
}


/// Represent a `Bool` as the strings "NO" and "YES". Parsing is case-insensitive. Serialization always stores uppercase.
public struct YesNoBooleanPropertyFormat: BooleanPropertyFormat {
    public init() {}
    
    public func parse(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "no": false
        case "yes": true
        default: nil
        }
    }
    
    public func serialize(_ bool: Bool) -> String {
        bool ? "YES" : "NO"
    }
}

extension BooleanPropertyFormat where Self == YesNoBooleanPropertyFormat {
    public static var yesNo: Self { .init() }
}

/// Represent a `Bool` as the strings "OFF" and "ON". Parsing is case-insensitive. Serialization always stores uppercase.
public struct OnOffBooleanPropertyFormat: BooleanPropertyFormat {
    public init() {}

    public func parse(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "off": false
        case "on": true
        default: nil
        }
    }
        
    public func serialize(_ bool: Bool) -> String {
        bool ? "ON" : "OFF"
    }
}

extension BooleanPropertyFormat where Self == OnOffBooleanPropertyFormat {
    public static var onOff: Self { .init() }
}

/// Represent a `Bool` as the strings "false" and "true". Parsing is case-insensitive. Serialization always stores lowercase.
public struct TrueFalseBooleanPropertyFormat: BooleanPropertyFormat {
    public init() {}
    
    public func parse(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "false": false
        case "true": true
        default: nil
        }
    }
    
    public func serialize(_ bool: Bool) -> String {
        bool ? "true" : "false"
    }
}

extension BooleanPropertyFormat where Self == TrueFalseBooleanPropertyFormat {
    public static var trueFalse: Self { .init() }
}

/// This is a workaround for Swift 5.4's inability to correctly infer the format type
/// using the `Self` constraints on the various static properties.
public struct BooleanPropertyFormatFactory<Format: BooleanPropertyFormat> {
    public var format: Format
}

extension BooleanPropertyFormatFactory {
    public static var integer: BooleanPropertyFormatFactory<IntegerBooleanPropertyFormat<Int>> {
        .init(format: .init())
    }
    
    public static var oneZero: BooleanPropertyFormatFactory<OneZeroBooleanPropertyFormat> {
        .init(format: .init())
    }

    public static var yn: BooleanPropertyFormatFactory<YNBooleanPropertyFormat> {
        .init(format: .init())
    }

    public static var yesNo: BooleanPropertyFormatFactory<YesNoBooleanPropertyFormat> {
        .init(format: .init())
    }

    public static var onOff: BooleanPropertyFormatFactory<OnOffBooleanPropertyFormat> {
        .init(format: .init())
    }

    public static var trueFalse: BooleanPropertyFormatFactory<TrueFalseBooleanPropertyFormat> {
        .init(format: .init())
    }
}
