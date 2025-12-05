import NIOCore

public extension EnumBuilder {
    func create() async throws -> DatabaseSchema.DataType {
        self.enum.action = .create
        try await self.database.execute(enum: self.enum)
        return try await self.generateDatatype()
    }
    
    func read() async throws -> DatabaseSchema.DataType {
        try await self.generateDatatype()
    }
    
    func update() async throws -> DatabaseSchema.DataType {
        self.enum.action = .update
        try await self.database.execute(enum: self.enum)
        return try await self.generateDatatype()
    }
    
    func delete() async throws {
        self.enum.action = .delete
        try await self.database.execute(enum: self.enum)
        try await self.deleteMetadata()
    }

    // MARK: Private 

    func generateDatatype() async throws -> DatabaseSchema.DataType {
        try await EnumMetadata.migration.prepare(on: self.database)
        try await self.updateMetadata()

        let cases = try await EnumMetadata.query(on: self.database).filter(\.$name == self.enum.name).all()  

        return .enum(.init(
            name: self.enum.name,
            cases: cases.map { $0.case }
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
        let count = try await EnumMetadata.query(on: self.database).count()

        // If no enums are left, remove table.
        if count == 0 {
            try await EnumMetadata.migration.revert(on: self.database)
        }
    }
}
