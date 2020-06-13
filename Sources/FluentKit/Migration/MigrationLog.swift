/// Stores information about `Migration`s that have been run.
public final class MigrationLog: Model {
    public static let schema = "_fluent_migrations"

    public static var migration: Migration {
        return MigrationLogMigration()
    }

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Field(key: "batch")
    public var batch: Int

    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() { }

    public init(id: IDValue? = nil, name: String, batch: Int) {
        self.id = id
        self.name = name
        self.batch = batch
        self.createdAt = nil
        self.updatedAt = nil
    }
}

private struct MigrationLogMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("_fluent_migrations")
            .field(.id, .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("batch", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "name")
            .ignoreExisting()
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("_fluent_migrations").delete()
    }
}

// This migration just exists to smooth the gap between
// how migrations were named between the first FluentKit 1
// alpha and the FluentKit 1.0.0 release.
@available(*, deprecated, message: "Remove in FluentKit 2")
struct V1NameMigration: Migration {
    let nameMapping: [String: String]

    init(allMigrations: [Migration]) {
        // map from old style default names
        // to new style default names
        var migrationNameMap = [String: String]()

        // a set of names that are manually
        // chosen by migration author.
        var nameOverrides = Set<String>()

        for migration in allMigrations {
            let releaseCandidateDefaultName = "\(type(of: migration))"
            let v4DefaultName = String(reflecting:type(of: migration))

            // if the migration does not override the default name.
            // NOTE we compare to the _current_ style of default, not
            // the release candidate style of default name.
            if migration.name == v4DefaultName {
                migrationNameMap[releaseCandidateDefaultName] = v4DefaultName
            } else {
                nameOverrides.insert(migration.name)
            }
        }
        // we must not rename anything that has an overridden
        // name that happens to be the same as the old-style
        // of default name.
        for overriddenName in nameOverrides {
            migrationNameMap.removeValue(forKey: overriddenName)
        }

        nameMapping = migrationNameMap
    }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        let queries = nameMapping.map { oldName, newName in
            MigrationLog.query(on: database)
                .filter(\.$name == oldName)
                .set(\.$name, to: newName)
                .update()
        }
        return database.eventLoop.flatten(queries)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        // must we revert this migration?
        return database.eventLoop.makeSucceededFuture(())
    }
}
