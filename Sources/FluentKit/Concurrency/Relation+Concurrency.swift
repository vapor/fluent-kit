import NIOCore
import SQLKit

public extension Relation {
    func get(reload: Bool = false, on database: any Database, annotationContext: SQLAnnotationContext? = nil) async throws -> RelatedValue {
        try await self.get(reload: reload, on: database, annotationContext: annotationContext).get()
    }
}
