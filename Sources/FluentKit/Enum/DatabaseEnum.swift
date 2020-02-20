public struct DatabaseEnum {
    public enum Action {
        case create
        case update
        case delete
    }

    public var action: Action
    public var name: String

    public var createCases: [String]
    public var deleteCases: [String]

    public init(name: String) {
        self.action = .create
        self.name = name
        self.createCases = []
        self.deleteCases = []
    }
}

extension DatabaseEnum {
    func generateDatatype(on database: Database) -> EventLoopFuture<DatabaseSchema.DataType> {
        self.initializeMetadata(on: database).flatMap {
            self.updateMetadata(on: database)
        }.flatMap { _ in
            // Fetch the latest cases.
            EnumMetadata.query(on: database).filter(\.$name == self.name).all()
        }.map { cases in
            // Convert latest cases to usable DataType.
            .enum(.init(
                name: self.name,
                cases: cases.map { $0.case }
            ))
        }
    }

    private func initializeMetadata(on database: Database) -> EventLoopFuture<Void> {
        // Check to see if the table exists.
        EnumMetadata.query(on: database).count().map { _ in
            // Ignore count.
        }.flatMapError { error in
            // Table does not exist, create it.
            EnumMetadata.migration.prepare(on: database)
        }
    }

    private func updateMetadata(on database: Database) -> EventLoopFuture<Void> {
        // Create all new enum cases.
        let create = self.createCases.map {
            EnumMetadata(name: self.name, case: $0)
        }.create(on: database)
        // Delete all old enum cases.
        let delete = EnumMetadata.query(on: database)
            .filter(\.$name == self.name)
            .filter(\.$case ~~ self.deleteCases)
            .delete()
        return create.and(delete).map { _ in }
    }

    private func deleteMetadata(on database: Database) -> EventLoopFuture<Void> {
        // Delete all cases for this enum.
        EnumMetadata.query(on: database)
            .filter(\.$name == self.name)
            .delete()
            .flatMap
        { _ in
            EnumMetadata.query(on: database).count()
        }.flatMap { count in
            // If no enums are left, remove table.
            if count == 0 {
                return EnumMetadata.migration.revert(on: database)
            } else {
                return database.eventLoop.makeSucceededFuture(())
            }
        }
    }
}
