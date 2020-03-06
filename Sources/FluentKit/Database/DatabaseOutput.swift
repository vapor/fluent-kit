public protocol DatabaseOutput: CustomStringConvertible {
    func schema(_ schema: String) -> DatabaseOutput
    func contains(_ path: [FieldKey]) -> Bool
    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T: Decodable
}

extension DatabaseOutput {
    public func contains(_ path: FieldKey...) -> Bool {
        self.contains(path)
    }
    
    public func decode<T>(_ path: [FieldKey]) throws -> T
        where T: Decodable
    {
        try self.decode(path, as: T.self)
    }

    public func decode<T>(_ path: FieldKey..., as type: T.Type = T.self) throws -> T
        where T: Decodable
    {
        try self.decode(path, as: T.self)
    }
}
