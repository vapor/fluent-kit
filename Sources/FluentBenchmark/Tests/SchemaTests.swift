import FluentKit
import Foundation
import NIOCore
import XCTest
import SQLKit
import FluentSQL

extension FluentBenchmarker {
    public func testSchema(foreignKeys: Bool = true) throws {
        try self.testSchema_addConstraint()
        try self.testSchema_addNamedConstraint()
        if foreignKeys {
            try self.testSchema_fieldReference()
        }
        if self.database is SQLDatabase {
            try self.testSchema_customSqlConstraints()
            try self.testSchema_customSqlFields()
            try self.testSchema_deleteConstraints()
        }
    }

    private func testSchema_addConstraint() throws {
        try self.runTest(#function, [
            CreateCategories()
        ]) {
            guard let sql = self.database as? SQLDatabase, sql.dialect.alterTableSyntax.allowsBatch else {
                self.database.logger.warning("Skipping \(#function)")
                return
            }
            // Add unique constraint
            try AddUniqueConstraintToCategories().prepare(on: self.database).wait()

            try Category(name: "a").create(on: self.database).wait()
            try Category(name: "b").create(on: self.database).wait()
            do {
                try Category(name: "a").create(on: self.database).wait()
                XCTFail("Duplicate save should have errored")
            } catch let error as DatabaseError where error.isConstraintFailure {
                // pass
            }

            // Remove unique constraint
            try AddUniqueConstraintToCategories().revert(on: self.database).wait()
            try Category(name: "a").create(on: self.database).wait()
        }
    }

    private func testSchema_addNamedConstraint() throws {
        try self.runTest(#function, [
            CreateCategories()
        ]) {
            guard let sql = self.database as? SQLDatabase, sql.dialect.alterTableSyntax.allowsBatch else {
                self.database.logger.warning("Skipping \(#function)")
                return
            }
            // Add unique constraint
            try AddNamedUniqueConstraintToCategories().prepare(on: self.database).wait()

            try Category(name: "a").create(on: self.database).wait()
            try Category(name: "b").create(on: self.database).wait()
            do {
                try Category(name: "a").create(on: self.database).wait()
                XCTFail("Duplicate save should have errored")
            } catch let error as DatabaseError where error.isConstraintFailure {
                // pass
            }

            // Remove unique constraint
            try AddNamedUniqueConstraintToCategories().revert(on: self.database).wait()
            try Category(name: "a").create(on: self.database).wait()
        }
    }
    
    private func testSchema_fieldReference() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            XCTAssertThrowsError(
                try Star.query(on: self.database)
                    .filter(\.$name == "Sun")
                    .delete(force: true).wait()
            )
        }
    }

    private func testSchema_customSqlConstraints() throws {
        try self.runTest(#function, [
            DeleteTableMigration(name: "custom_constraints")
        ]) {
            let normalized1 = (self.database as! SQLDatabase).dialect.normalizeSQLConstraint(identifier: SQLIdentifier("id_unq_1"))
            
            try self.database.schema("custom_constraints")
                .id()
                
                // Test query string SQL for entire table constraints:
                .constraint(.sql(embed: "CONSTRAINT \(normalized1) UNIQUE (\(ident: "id"))"))
                
                // Test raw SQL for table constraint definitions (but not names):
                .constraint(.constraint(.sql(raw: "UNIQUE (id)"), name: "id_unq_2"))
                .constraint(.constraint(.sql(embed: "UNIQUE (\(ident: "id"))"), name: "id_unq_3"))
                
                .create().wait()
            
            if (self.database as! SQLDatabase).dialect.alterTableSyntax.allowsBatch {
                try self.database.schema("custom_constraints")
                    // Test raw SQL for dropping constraints:
                    .deleteConstraint(.sql(embed: "\(SQLDropTypedConstraint(name: SQLIdentifier("id_unq_1"), algorithm: .sql(raw: "")))"))
                    .update().wait()
            }
        }
    }

    private func testSchema_customSqlFields() throws {
        try self.runTest(#function, [
            DeleteTableMigration(name: "custom_fields")
        ]) {
            try self.database.schema("custom_fields")
                .id()
                
                // Test query string SQL for field data types:
                .field("morenotid", .sql(embed: "\(raw: "TEXT")"))
                
                // Test raw SQL for field names:
                .field(.definition(name: .sql(embed: "\(ident: "stillnotid")"), dataType: .int, constraints: [.required]))
                
                // Test raw SQL for field constraints:
                .field("neverbeid", .string, .sql(embed: "NOT NULL"))
                
                // Test raw SQL for entire field definitions:
                .field(.sql(raw: "idnah INTEGER NOT NULL"))
                .field(.sql(embed: "\(ident: "notid") INTEGER"))
                
                .create().wait()
                
            if (self.database as! SQLDatabase).dialect.alterTableSyntax.allowsBatch {
                try self.database.schema("custom_fields")
                    
                    // Test raw SQL for field updates:
                    .updateField(.sql(embed: "\(SQLAlterColumnDefinitionType(column: .init("notid"), dataType: .text))"))
                    
                    .update().wait()
            }
        }
    }
    
    private func testSchema_deleteConstraints() throws {
        try self.runTest(#function, [
            CreateCategories(),
            DeleteTableMigration(name: "normal_constraints")
        ]) {
            try self.database.schema("normal_constraints")
                .id()
                
                .field("catid", .uuid)
                .foreignKey(["catid"], references: Category.schema, [.id], onDelete: .noAction, onUpdate: .noAction)
                .unique(on: "catid")
                
                .create().wait()
            
            if (self.database as! SQLDatabase).dialect.alterTableSyntax.allowsBatch {
                try self.database.schema("normal_constraints")
                    // Test `DROP FOREIGN KEY` (MySQL) or `DROP CONSTRAINT` (Postgres)
                    .deleteConstraint(.constraint(.foreignKey([.key("catid")], Category.schema, [.key(.id)], onDelete: .noAction, onUpdate: .noAction)))
                    // Test `DROP KEY` (MySQL) or `DROP CONSTRAINT` (Postgres)
                    .deleteUnique(on: "catid")
                    
                    .update().wait()
            }
        }
    }
}

final class Category: Model {
    static let schema = "categories"
    @ID var id: UUID?
    @Field(key: "name") var name: String
    init() { }
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct CreateCategories: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .id()
            .field("name", .string, .required)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .delete()
    }
}

struct AddUniqueConstraintToCategories: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .unique(on: "name")
            .update()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .deleteUnique(on: "name")
            .update()
    }
}


struct AddNamedUniqueConstraintToCategories: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .unique(on: "name", name: "foo")
            .update()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .deleteConstraint(name: "foo")
            .update()
    }
}

/// Specialized utility used by the custom SQL tests, used to ensure they clean up after themselves.
struct DeleteTableMigration: Migration {
    let name: String
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.future()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(self.name).delete()
    }
}
