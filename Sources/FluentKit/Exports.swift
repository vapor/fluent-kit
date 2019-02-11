@_exported import NIO

#warning("TODO: move to codable kit")
/// A generic `String` based `CodingKey` implementation.
public struct StringCodingKey: CodingKey {
    /// `CodingKey` conformance.
    public var stringValue: String
    
    /// `CodingKey` conformance.
    public var intValue: Int? {
        return Int(self.stringValue)
    }
    
    /// Creates a new `StringCodingKey`.
    public init(_ string: String) {
        self.stringValue = string
    }
    
    /// `CodingKey` conformance.
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    /// `CodingKey` conformance.
    public init?(intValue: Int) {
        self.stringValue = intValue.description
    }
}

/// Used to unwrap the `Decoder` from a private implementation like `JSONDecoder`.
///
///     let unwrapper = try JSONDecoder().decode(DecoderUnwrapper.self, from: ...)
///     print(unwrapper.decoder) // Decoder
///
struct DecoderUnwrapper: Decodable {
    /// The unwrapped `Decoder`.
    public let decoder: Decoder
    
    /// `Decodable` conformance.
    public init(from decoder: Decoder) {
        self.decoder = decoder
    }
}
