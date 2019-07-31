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

extension DatabaseOutput {
    func cascading(to output: DatabaseOutput) -> DatabaseOutput {
        return CombinedOutput(first: self, second: output)
    }
}

private struct CombinedOutput: DatabaseOutput {
    var first: DatabaseOutput
    var second: DatabaseOutput

    func contains(field: String) -> Bool {
        return self.first.contains(field: field) || self.second.contains(field: field)
    }

    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        if self.first.contains(field: field) {
            return try self.first.decode(field: field, as: T.self)
        } else if self.second.contains(field: field) {
            return try self.second.decode(field: field, as: T.self)
        } else {
            throw FluentError.missingField(name: field)
        }
    }

    var description: String {
        return self.first.description + " -> " + self.second.description
    }
}

