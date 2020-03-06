extension DatabaseOutput {
    func cascading(to output: DatabaseOutput) -> DatabaseOutput {
        return CombinedOutput(first: self, second: output)
    }
}

private struct CombinedOutput: DatabaseOutput {
    var first: DatabaseOutput
    var second: DatabaseOutput

    func contains(_ path: [FieldKey]) -> Bool {
        self.first.contains(path) || self.second.contains(path)
    }

    func schema(_ schema: String) -> DatabaseOutput {
        CombinedOutput(
            first: self.first.schema(schema),
            second: self.second.schema(schema)
        )
    }

    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T: Decodable
    {
        if self.first.contains(path) {
            return try self.first.decode(path)
        } else if self.second.contains(path) {
            return try self.second.decode(path)
        } else {
            throw FluentError.missingField(name: path.description)
        }
    }

    var description: String {
        return self.first.description + " -> " + self.second.description
    }
}
