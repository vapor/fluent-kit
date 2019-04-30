public protocol DatabaseOutput: CustomStringConvertible {
    func contains(field: String) -> Bool
    func decode<T>(field: String, as type: T.Type) throws -> T
        where T: Decodable
}
