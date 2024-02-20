import SQLKit
import FluentKit

extension SQLQueryFetcher {
    public func first<Model>(decoding model: Model.Type) -> EventLoopFuture<Model?> 
        where Model: FluentKit.Model
    {
        self.all(decoding: Model.self).map { $0.first }
    }

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

extension SQLRow {
    public func decode<Model>(model: Model.Type) throws -> Model
        where Model: FluentKit.Model
    {
        let model = Model()
        try model.output(from: SQLDatabaseOutput(sql: self))
        return model
    }
}

internal struct SQLDatabaseOutput: DatabaseOutput {
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

