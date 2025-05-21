import NIOCore
import SQLKit

public extension OptionalChildProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
    
    func create(_ to: To, on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.create(to, on: database, annotationContext: annotationContext).get()
    }
}

public extension CompositeOptionalChildProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
}
