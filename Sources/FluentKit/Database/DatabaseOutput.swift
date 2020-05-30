public protocol DatabaseOutput: CustomStringConvertible {
    func schema(_ schema: String) -> DatabaseOutput
    func contains(_ key: FieldKey) -> Bool
    func decodeNil(_ key: FieldKey) throws -> Bool
    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
}

extension DatabaseOutput {
    public func decode<T>(_ key: FieldKey) throws -> T
        where T: Decodable
    {
        try self.decode(key, as: T.self)
    }
}
