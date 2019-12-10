import Foundation
import FluentKit

final class Trash: Model {
    static let schema = "trash"

    @ID(key: "id")
    var id: UUID?

    @Field(key: "contents")
    var contents: String

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() { }

    init(contents: String) {
        self.contents = contents
    }
}

struct TrashMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Trash.schema)
            .field("id", .uuid, .identifier(auto: true))
            .field("contents", .string, .required)
            .field("deleted_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Trash.schema).delete()
    }
}
