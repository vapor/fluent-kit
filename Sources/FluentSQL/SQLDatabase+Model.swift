import SQLKit

extension SQLQueryFetcher {
    public func all<Model>(decoding model: Model.Type) -> EventLoopFuture<[Model]> 
        where Model: FluentKit.Model
    {
        self.all().flatMapThrowing { rows in 
            try rows.map { row in
                let model = Model()
                try model.output(from: SQLDatabaseOutput(sql: row))
                return model
            }
        }
    }
}

private struct SQLDatabaseOutput: DatabaseOutput {
    let sql: SQLRow

    var description: String {
        "\(self.sql)"
    }

    func schema(_ schema: String) -> DatabaseOutput {
        self
    }

    func contains(_ key: FieldKey) -> Bool {
        self.sql.contains(column: key.description)
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.sql.decodeNil(column: key.description)
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T 
        where T: Decodable
    {
        try self.sql.decode(column: key.description, as: T.self)
    }
}

