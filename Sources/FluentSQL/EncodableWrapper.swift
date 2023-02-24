import Foundation

/// Wraps a non-generic `Encodable` type for passing to a method that requires
/// a strong type.
///
///     let encodable: Encodable ...
///     let data = try JSONEncoder().encode(EncodableWrapper(encodable))
///
struct EncodableWrapper: Encodable {
    /// Wrapped `Encodable` type.
    public let encodable: Encodable
    
    /// Creates a new `EncoderWrapper`.
    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    /// `Encodable` conformance.
    public func encode(to encoder: Encoder) throws {
        try self.encodable.encode(to: encoder)
    }
}
