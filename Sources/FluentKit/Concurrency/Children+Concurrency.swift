import NIOCore
import SQLKit

public extension ChildrenProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
    
    func create(_ to: To, on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.create(to, on: database, annotationContext: annotationContext).get()
    }
    
    func create(_ to: [To], on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.create(to, on: database, annotationContext: annotationContext).get()
    }
}

public extension CompositeChildrenProperty {
    func load(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.load(on: database, annotationContext: annotationContext).get()
    }
}
