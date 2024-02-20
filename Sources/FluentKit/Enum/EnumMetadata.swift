import NIOCore
import Foundation

final class EnumMetadata: Model {
    static let schema = "_fluent_enums"

    static var migration: Migration {
        return EnumMetadataMigration()
    }

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "case")
    var `case`: String

    init() { }

    init(id: IDValue? = nil, name: String, `case`: String) {
        self.id = id
        self.name = name
        self.case = `case`
    }
}

private struct EnumMetadataMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("_fluent_enums")
            .field(.id, .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("case", .string, .required)
            .unique(on: "name", "case")
            .ignoreExisting()
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("_fluent_enums").delete()
    }
}
