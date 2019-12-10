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

    init(id: UUID? = nil, contents: String) {
        if let id = id {
            self.id = id
            self._id.exists = true
        }
        self.contents = contents
    }
}

struct TrashMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let builder = database.schema(Trash.schema)
            .field("id", .uuid, .identifier(auto: false))
            .field("contents", .string, .required)
            .field("deleted_at", .datetime)

        builder.schema.constraints.append(.unique(fields: [.string("id")]))

        return builder.create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Trash.schema).delete()
    }
}
