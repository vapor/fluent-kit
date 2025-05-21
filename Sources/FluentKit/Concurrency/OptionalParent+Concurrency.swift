import NIOCore
import SQLKit

public extension OptionalParentProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
}

public extension CompositeOptionalParentProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
}
