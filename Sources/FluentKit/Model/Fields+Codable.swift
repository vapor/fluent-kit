import struct SQLKit.SomeCodingKey

extension Fields {
    public init(from decoder: any Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: SomeCodingKey.self)

        for (key, property) in self.codableProperties {
            let propDecoder = try container.superDecoder(forKey: key)
            do {
                try property.decode(from: propDecoder)
            } catch {
                throw DecodingError.typeMismatch(
                    type(of: property).anyValueType,
                    .init(
                        codingPath: container.codingPath + [key],
                        debugDescription: "Could not decode property",
                        underlyingError: error
                    ))
            }
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: SomeCodingKey.self)

        for (key, property) in self.codableProperties where !property.skipPropertyEncoding {
            do {
                try property.encode(to: container.superEncoder(forKey: key))
            } catch let error where error is EncodingError {  // trapping all errors breaks value handling logic in database driver layers
                throw EncodingError.invalidValue(
                    property.anyValue ?? "null",
                    .init(
                        codingPath: container.codingPath + [key],
                        debugDescription: "Could not encode property",
                        underlyingError: error
                    ))
            }
        }
    }
}
