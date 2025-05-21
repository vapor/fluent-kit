import NIOCore
import SQLKit

public extension Model {
    static func find(
        _ id: Self.IDValue?,
        on database: any Database,
        annotationContext: SQLAnnotationContext? = nil
    ) async throws -> Self? {
        try await self.find(id, on: database, annotationContext: annotationContext).get()
    }
    
    // MARK: - CRUD
    func save(on database: any Database, annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.save(on: database, annotationContext: annotationContext).get()
    }
    
    func create(on database: any Database, annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.create(on: database, annotationContext: annotationContext).get()
    }
    
    func update(on database: any Database, annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.update(on: database, annotationContext: annotationContext).get()
    }
    
    func delete(force: Bool = false, on database: any Database, annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.delete(force: force, on: database, annotationContext: annotationContext).get()
    }
    
    func restore(on database: any Database, annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.restore(on: database, annotationContext: annotationContext).get()
    }
}

public extension Collection where Element: FluentKit.Model, Self: Sendable {
    func delete(force: Bool = false, on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.delete(force: force, on: database, annotationContext: annotationContext).get()
    }
    
    func create(on database: any Database, annotationContext: SQLAnnotationContext?) async throws {
        try await self.create(on: database, annotationContext: annotationContext).get()
    }
}
