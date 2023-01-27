extension Fields {
    public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: SomeCodingKey.self)
        
        for (key, property) in self.codableProperties {
            let propDecoder = AirQuotesSafeSuperDecoder(container: container, key: key)
            
            do {
                try property.decode(from: propDecoder)
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
        var container = encoder.container(keyedBy: SomeCodingKey.self)
        
        for (key, property) in self.codableProperties where !property.skipPropertyEncoding {
            do {
                try property.encode(to: container.superEncoder(forKey: key))
            } catch let error where error is EncodingError { // trapping all errors breaks value handling logic in database driver layers
                throw EncodingError.invalidValue(property.anyValue ?? "null", .init(
                    codingPath: container.codingPath + [key],
                    debugDescription: "Could not encode property",
                    underlyingError: error
                ))
            }
        }
    }
}

/// This type's only purpose is to compensate for the changed behavior of `.superDecoder(forKey:)`, which used
/// to return a `Decoder` representing a `NULL` value when the key was not present, but since 5.5 on Linux (and
/// possibly eventually on macOS as well) will throw a key not found error for missing keys. Therefore, this
/// `Decoder` wraps the container from which the key is supposed to come and allows an additional level of
/// descent into the decode before an error would be thrown.
///
/// It is really unfortunate to need this; it's no win for peformance, for one. It's just the least unpleasant
/// alternative available as long as the overall semantics remain undisturbed.
private struct AirQuotesSafeSuperDecoder<K: CodingKey>: Decoder, SingleValueDecodingContainer {
    var codingPath: [CodingKey] { self.container.codingPath }
    var userInfo: [CodingUserInfoKey: Any] { [:] }
    let container: KeyedDecodingContainer<K>
    let key: K

    func container<NK: CodingKey>(keyedBy: NK.Type) throws -> KeyedDecodingContainer<NK> { try self.container.nestedContainer(keyedBy: NK.self, forKey: self.key) }
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { try self.container.nestedUnkeyedContainer(forKey: self.key) }
    func singleValueContainer() throws -> SingleValueDecodingContainer { self }
    func decode<T: Decodable>(_: T.Type) throws -> T { try self.container.decode(T.self, forKey: self.key) }
    func decodeNil() -> Bool { self.container.contains(self.key) ? try! self.container.decodeNil(forKey: self.key) : true }
}
