import NIOCore
import SQLKit

public extension ParentProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
}

public extension CompositeParentProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
}
