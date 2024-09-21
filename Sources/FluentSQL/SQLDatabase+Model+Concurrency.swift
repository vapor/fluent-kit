import NIOCore
import SQLKit
import FluentKit

extension SQLQueryFetcher {
    public func first<Model: FluentKit.Model>(decodingFluent model: Model.Type) async throws -> Model? {
        try await self.first(decodingFluent: Model.self).get()
    }
    
    @available(*, deprecated, renamed: "first(decodingFluent:)", message: "Renamed to first(decodingFluent:)")
    public func first<Model: FluentKit.Model>(decoding: Model.Type) async throws -> Model? {
        try await self.first(decodingFluent: Model.self)
    }

    public func all<Model: FluentKit.Model>(decodingFluent: Model.Type) async throws -> [Model] {
        try await self.all(decodingFluent: Model.self).get()
    }
    
    @available(*, deprecated, renamed: "all(decodingFluent:)", message: "Renamed to all(decodingFluent:)")
    public func all<Model: FluentKit.Model>(decoding: Model.Type) async throws -> [Model] {
        try await self.all(decodingFluent: Model.self)
    }
}
