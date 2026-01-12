import NIOCore
import Foundation

final class EnumMetadata: Model, @unchecked Sendable {
    static let schema = "_fluent_enums"

    static var migration: any AsyncMigration {
        EnumMetadataMigration()
    }

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "case")
    var `case`: String

    init() {}

    init(id: IDValue? = nil, name: String, `case`: String) {
        self.id = id
        self.name = name
        self.case = `case`
    }
}

private struct EnumMetadataMigration: AsyncMigration {
    func prepare(on database: any Database) async throws  {
        try await database.schema(EnumMetadata.schema)
            .id()
            .field("name", .string, .required)
            .field("case", .string, .required)
            .unique(on: "name", "case")
            .ignoreExisting()
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(EnumMetadata.schema).delete()
    }
}
