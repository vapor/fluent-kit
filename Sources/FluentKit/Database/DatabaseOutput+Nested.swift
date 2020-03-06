extension DatabaseOutput {
    func nested(_ key: FieldKey) -> DatabaseOutput {
        return NestedOutput(wrapped: self, prefix: key)
    }
}

private struct NestedOutput: DatabaseOutput {
    let wrapped: DatabaseOutput
    let prefix: FieldKey

    var description: String {
        self.wrapped.description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        self.wrapped.schema(schema)
    }

    func contains(_ path: [FieldKey]) -> Bool {
        self.wrapped.contains([self.prefix] + path)
    }

    func decode<T>(_ path: [FieldKey], as type: T.Type) throws -> T
        where T : Decodable
    {
        try self.wrapped.decode([self.prefix] + path)
    }
}
