public protocol DatabaseOutput: CustomStringConvertible {
    func contains(field: String) -> Bool
    func decode<T>(field: String, as type: T.Type) throws -> T
        where T: Decodable
}

extension DatabaseOutput {
    func prefixed(by string: String) -> DatabaseOutput {
        return PrefixingOutput(self, prefix: string)
    }
}

private struct PrefixingOutput: DatabaseOutput {
    let wrapped: DatabaseOutput

    let prefix: String

    var description: String {
        return self.wrapped.description
    }

    init(_ wrapped: DatabaseOutput, prefix: String) {
        self.wrapped = wrapped
        self.prefix = prefix
    }

    func contains(field: String) -> Bool {
        return self.wrapped.contains(field: self.prefix + field)
    }

    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.wrapped.decode(field: self.prefix + field, as: T.self)
    }
}
