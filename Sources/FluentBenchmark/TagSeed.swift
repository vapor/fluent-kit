import FluentKit

final class TagSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return ["Small Rocky", "Gas Giant", "Inhabited"].map { name in
            return Tag(name: name)
        }.create(on: database)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Tag.query(on: database).delete()
    }
}
