extension Fields {
    public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: MissingStdlibAPICodingKey.self)
        
        for (key, property) in self.codableProperties {
            do {
                try property.decode(from: container.superDecoder(forKey: key))
            } catch {
                throw DecodingError.typeMismatch(type(of: property).anyValueType, .init(
                    codingPath: container.codingPath + [key],
                    debugDescription: "Could not decode property",
                    underlyingError: error
                ))
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MissingStdlibAPICodingKey.self)
        
        for (key, property) in self.codableProperties where !property.skipPropertyEncoding {
            do {
                try property.encode(to: container.superEncoder(forKey: key))
            } catch {
                throw EncodingError.invalidValue(property.anyValue ?? "null", .init(
                    codingPath: container.codingPath + [key],
                    debugDescription: "Could not encode property",
                    underlyingError: error
                ))
            }
        }
    }
}

/// A 100% conformance to ``Swift/CodingKey``, the standard library's version of a protocol
/// whose reqirements are trapped in a looping crisis of personal identity.
internal struct MissingStdlibAPICodingKey: CodingKey, Hashable {
  internal let stringValue: String, intValue: Int?
  internal init(stringValue: String) { (self.stringValue, self.intValue) = (stringValue, Int(stringValue)) }
  internal init(intValue: Int) { (self.stringValue, self.intValue) = ("\(intValue)", intValue) }
}
