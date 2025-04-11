import AsyncAlgorithms
import NIOConcurrencyHelpers
import SQLKit

extension Database {
    public func `enum`(_ name: String) -> EnumBuilder {
        .init(database: self, name: name)
    }
}

public final class EnumBuilder: Sendable {
    let database: any Database
    let lockedEnum: NIOLockedValueBox<DatabaseEnum>

    public var `enum`: DatabaseEnum {
        get { self.lockedEnum.withLockedValue { $0 } }
        set { self.lockedEnum.withLockedValue { $0 = newValue } }
    }

    init(database: any Database, name: String) {
        self.database = database
        self.lockedEnum = .init(.init(name: name))
    }

    public func `case`(_ name: String) -> Self {
        self.enum.createCases.append(name)
        return self
    }

    public func deleteCase(_ name: String) -> Self {
        self.enum.deleteCases.append(name)
        return self
    }

    public func create() async throws -> DatabaseSchema.DataType {
        self.enum.action = .create
        try await self.database.execute(enum: self.enum)
        return try await self.generateDatatype()
    }

    public func read() async throws -> DatabaseSchema.DataType {
        try await self.generateDatatype()
    }

    public func update() async throws -> DatabaseSchema.DataType {
        self.enum.action = .update
        try await self.database.execute(enum: self.enum)
        return try await self.generateDatatype()
    }

    public func delete() async throws {
        self.enum.action = .delete
        try await self.database.execute(enum: self.enum)
        return try await self.deleteMetadata()
    }

    // MARK: Private

    private func generateDatatype() async throws -> DatabaseSchema.DataType {
        try await EnumMetadata.migration.prepare(on: self.database)
        try await self.updateMetadata()

        // Fetch the latest cases.
        let cases = try await EnumMetadata.query(on: self.database).filter(\.$name == self.enum.name).all()

        // Convert latest cases to usable DataType.
        return .enum(.init(
            name: self.enum.name,
            cases: try await Array(cases).map { $0.case }
        ))
    }

    private func updateMetadata() async throws {
        // Create all new enum cases.
        try await self.enum.createCases.map {
            EnumMetadata(name: self.enum.name, case: $0)
        }.create(on: self.database)
        // Delete all old enum cases.
        try await EnumMetadata.query(on: self.database)
            .filter(\.$name == self.enum.name)
            .filter(\.$case ~~ self.enum.deleteCases)
            .delete()
    }

    private func deleteMetadata() async throws {
        // Delete all cases for this enum.
        try await EnumMetadata.query(on: self.database)
            .filter(\.$name == self.enum.name)
            .delete()

        if try await EnumMetadata.query(on: self.database).count() == 0 {
            // If no enums are left, remove table.
            try await EnumMetadata.migration.revert(on: self.database)
        }
    }
}
