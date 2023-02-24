import NIOCore
import SQLKit

extension Database {
    public func `enum`(_ name: String) -> EnumBuilder {
        .init(database: self, name: name)
    }
}

public final class EnumBuilder {
    let database: Database
    public var `enum`: DatabaseEnum

    init(database: Database, name: String) {
        self.database = database
        self.enum = .init(name: name)
    }

    public func `case`(_ name: String) -> Self {
        self.enum.createCases.append(name)
        return self
    }

    public func deleteCase(_ name: String) -> Self {
        self.enum.deleteCases.append(name)
        return self
    }

    public func create() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.enum.action = .create
        return self.database.execute(enum: self.enum).flatMap {
            self.generateDatatype()
        }
    }

    public func read() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.generateDatatype()
    }

    public func update() -> EventLoopFuture<DatabaseSchema.DataType> {
        self.enum.action = .update
        return self.database.execute(enum: self.enum).flatMap {
            self.generateDatatype()
        }
    }

    public func delete() -> EventLoopFuture<Void> {
        self.enum.action = .delete
        return self.database.execute(enum: self.enum).flatMap {
            self.deleteMetadata()
        }
    }

    // MARK: Private

    private func generateDatatype() -> EventLoopFuture<DatabaseSchema.DataType> {
        EnumMetadata.migration.prepare(on: self.database).flatMap {
            self.updateMetadata()
        }.flatMap { _ in
            // Fetch the latest cases.
            EnumMetadata.query(on: self.database).filter(\.$name == self.enum.name).all()
        }.map { cases in
            // Convert latest cases to usable DataType.
            .enum(.init(
                name: self.enum.name,
                cases: cases.map { $0.case }
            ))
        }
    }

    private func updateMetadata() -> EventLoopFuture<Void> {
        // Create all new enum cases.
        let create = self.enum.createCases.map {
            EnumMetadata(name: self.enum.name, case: $0)
        }.create(on: self.database)
        // Delete all old enum cases.
        let delete = EnumMetadata.query(on: self.database)
            .filter(\.$name == self.enum.name)
            .filter(\.$case ~~ self.enum.deleteCases)
            .delete()
        return create.and(delete).map { _ in }
    }

    private func deleteMetadata() -> EventLoopFuture<Void> {
        // Delete all cases for this enum.
        EnumMetadata.query(on: self.database)
            .filter(\.$name == self.enum.name)
            .delete()
            .flatMap
        { _ in
            EnumMetadata.query(on: self.database).count()
        }.flatMap { count in
            // If no enums are left, remove table.
            if count == 0 {
                return EnumMetadata.migration.revert(on: self.database)
            } else {
                return self.database.eventLoop.makeSucceededFuture(())
            }
        }
    }
}
