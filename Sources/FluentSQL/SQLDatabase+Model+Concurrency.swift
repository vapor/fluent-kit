import NIOCore
import SQLKit
import FluentKit

extension SQLQueryFetcher {
    public func first<Model>(decoding model: Model.Type) async throws -> Model?
        where Model: FluentKit.Model
    {
        return try await self.all(decoding: Model.self).map { $0.first }.get()
    }

    public func all<Model>(decoding model: Model.Type) async throws -> [Model]
        where Model: FluentKit.Model
    {
        return try await self.all().flatMapThrowing { rows in
            try rows.map { row in
                let model = Model()
                try model.output(from: SQLDatabaseOutput(sql: row))
                return model
            }
        }.get()
    }
}
