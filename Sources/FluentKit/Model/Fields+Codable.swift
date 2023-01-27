extension Fields {
    public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: SomeCodingKey.self)
        
        for (key, property) in self.codableProperties {
#if swift(<5.7.1)
            let propDecoder = WorkaroundSuperDecoder(container: container, key: key)
#else
            let propDecoder = try container.superDecoder(forKey: key)
#endif
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

#if swift(<5.7.1)
/// This ``Decoder`` compensates for a bug in `KeyedDecodingContainerProtocol.superDecoder(forKey:)` on Linux
/// which first appeared in Swift 5.5 and was fixed in Swift 5.7.1.
///
/// When a given key is not present in the input JSON, `.superDecoder(forKey:)` is expected to return a valid
/// ``Decoder`` that will only decode a nil value. However, in affected versions of Swift, the method instead
/// throws a ``DecodingError/keyNotFound``.
///
/// As a workaround, instead of calling `.superDecoder(forKey:)`, an instance of this type is created and
/// provided with the decoding container; the apporiate decoding methods are intercepted to provide the
/// desired semantics, with everything else being forwarded directly to the container. This has a minor but
/// nonzero impact on performance, but was determined to be the best and cleanest option.
private struct WorkaroundSuperDecoder<K: CodingKey>: Decoder, SingleValueDecodingContainer {
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
#endif
